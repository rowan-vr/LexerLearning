%{
#include <stdio.h>
#include <stdbool.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>

#define LEX_BUFFER_SIZE 1024

// Error checking mutex lock and unlock helpers
#define my_pthread_mutex_lock(mut) do {\
	int res = pthread_mutex_lock(&lexer_state_mutex);\
	if (res != 0) {\
		fprintf(stderr, "pthread_mutex_lock errored: %s\n", strerror(res));\
		exit(1);\
	}\
} while (0)
#define my_pthread_mutex_unlock(mut) do {\
	int res = pthread_mutex_unlock(&lexer_state_mutex);\
	if (res != 0) {\
		fprintf(stderr, "pthread_mutex_unlock errored: %s\n", strerror(res));\
		exit(1);\
	}\
} while (0)

// From test.h
extern int yylex_init (yyscan_t* scanner);
extern int yylex_destroy ( yyscan_t yyscanner );
extern int yylex (yyscan_t yyscanner);
extern void yyset_in  ( FILE * _in_str , yyscan_t yyscanner );

enum Token {
	ERROR = -1,
	NOTOKEN = 1,
	NUMBER = 2,
	WHITESPACE = 3,
	IDENT = 4,
	UNKNOWN = 99
};
struct Tokens {
	enum Token first;
	enum Token second;
};


// Mutex to protect the lexer state
pthread_mutex_t lexer_state_mutex = PTHREAD_MUTEX_INITIALIZER;
enum lexer_state {init, reading, processing, done} lexer_state = init;
const char *lexer_state_names[] =
	{ [init] = "init"
	, [reading] = "reading"
	, [processing] = "processing"
	, [done] = "done"
	};

void set_lexer_state(enum lexer_state ls)
{
	my_pthread_mutex_lock(&lexer_state_mutex);
	lexer_state = ls;
	my_pthread_mutex_unlock(&lexer_state_mutex);
}

enum lexer_state get_lexer_state()
{
	my_pthread_mutex_lock(&lexer_state_mutex);
	enum lexer_state ls = lexer_state;
	my_pthread_mutex_unlock(&lexer_state_mutex);
	return ls;
}

struct lex_state {
	pthread_t thread;
	FILE *fhandle;
	// Character buffer
	size_t cstart;
	size_t cend;
	int cbuf[LEX_BUFFER_SIZE];
	// Token buffer
	size_t tstart;
	size_t tend;
	enum Token tbuf[LEX_BUFFER_SIZE];
};

void *lexerThread(void *vargp)
{
	enum Token tok;
	struct lex_state *cookie = (struct lex_state *)vargp;
	yyscan_t yyscanner;
	yylex_init(&yyscanner);
	yyset_in(cookie->fhandle, yyscanner);

	set_lexer_state(processing);
	while ((tok = yylex(yyscanner)) != 0) {
		cookie->tbuf[(cookie->tend++) % LEX_BUFFER_SIZE] = tok;
	}
	yylex_destroy(yyscanner);
	set_lexer_state(done);
	return vargp;
}

ssize_t bi_read(void *cookie_vp, char *buf, size_t size)
{
	struct lex_state *cookie = (struct lex_state *)cookie_vp;
	set_lexer_state(reading);

	// This blocks until there is data
	while (size > 0 && cookie->cstart == cookie->cend) {
		sched_yield();
	}

	ssize_t numread = 0;
	while (size > 0 && cookie->cstart != cookie->cend) {
		// Out of data
		if (cookie->cstart == cookie->cend) {
			break;
		}
		// Eof
		if (cookie->cbuf[cookie->cstart % LEX_BUFFER_SIZE] == EOF) {
			break;
		}
		buf[numread++] = cookie->cbuf[(cookie->cstart++) % LEX_BUFFER_SIZE];
	}
	cookie->cend %= LEX_BUFFER_SIZE;
	cookie->cstart %= LEX_BUFFER_SIZE;

	set_lexer_state(processing);
	return numread;
}

struct Tokens lex_one_char(struct lex_state *cookie, int c)
{
	// Put character in buffer
	cookie->cbuf[(cookie->cend++) % LEX_BUFFER_SIZE] = c;

	// Wait until character buffer is again empty
	if (c != EOF) {
		while (cookie->cend != cookie->cstart) {
			sched_yield();
		}
		while (get_lexer_state() != reading) {
			sched_yield();
		}
	} else {
		while (get_lexer_state() != done) {
			sched_yield();
		}
	}

	struct Tokens res = { .first=NOTOKEN, .second=NOTOKEN};
	switch (cookie->tend - cookie->tstart) {
	case 0:
		break;
	case 1:
		res.first = cookie->tbuf[cookie->tstart++];
		break;
	case 2:
		res.first = cookie->tbuf[cookie->tstart++];
		res.second = cookie->tbuf[cookie->tstart++];
		break;
	default:
		fprintf(stderr, "lexer pushed three tokens or more?\n");
		res.first = ERROR;
		break;
	}
	return res;
}

struct lex_state *lexer_setup()
{
	int res;
	// Allocate state
	struct lex_state *buf = (struct lex_state *)calloc(1, sizeof(struct lex_state));
	if (buf == NULL) {
		perror("calloc");
		return NULL;
	}

	// Open cookie
	buf->fhandle = fopencookie(buf, "r", (cookie_io_functions_t)
		{ .read=&bi_read
		, .write=NULL
		, .seek=NULL
		, .close=NULL
		});
	if (buf->fhandle == NULL) {
		perror("fopencookie");
		return NULL;
	}

	// Start lexer thread
	if ((res = pthread_create(&buf->thread, NULL, lexerThread, buf)) != 0) {
		fprintf(stderr, "pthread_create: %s\n", strerror(res));
		return NULL;
	}

	// Wait for the lexer to be ready starting up
	while (get_lexer_state() == init) {
		sched_yield();
	}
	return buf;
}

bool lexer_destroy(struct lex_state *buf)
{
	// Send eof
	lex_one_char(buf, EOF);
	// Close thread?
	struct timespec tv;
	// Get current time
	if (clock_gettime(CLOCK_REALTIME, &tv) != 0) {
		perror("clock_gettime");
		return false;
	}
	// Wait for at most one second
	tv.tv_sec += 1;
	void *retval;
	int res = pthread_timedjoin_np(buf->thread, &retval, &tv);
	if (res != 0) {
		if (res == ETIMEDOUT) {
			fprintf(stderr, "lexer thread was still running, killing\n");
			if ((res = pthread_kill(buf->thread, SIGINT)) != 0) {
				fprintf(stderr, "pthread_kill: %s\n", strerror(res));
				return false;
			}
		} else {
			fprintf(stderr, "pthread_join: %s\n", strerror(res));
			return false;
		}
	}

	// Close file
	if (fclose(buf->fhandle) == EOF) {
		perror("fclose");
		free(buf);
		return false;
	}
	// Free buffer
	free(buf);
	return true;
}

char print_char_buf[] = "'XX'";
char *print_char(char c)
{
	switch (c) {
	case '\n':
		strcpy(print_char_buf, "'\\n'");
		break;
	case EOF:
		strcpy(print_char_buf, "EOF");
		break;
	default:
		sprintf(print_char_buf, "'%c'", c);
		break;
	}
	return print_char_buf;
}

char print_token_buf[] = "XXX";
void print_token(enum Token t, FILE *f)
{
	switch (t) {
	case ERROR:
		fprintf(f, "Err");
		break;
	case NOTOKEN:
//		fprintf(f, "Not");
		break;
	case NUMBER:
		fprintf(f, "Num");
		break;
	case WHITESPACE:
		fprintf(f, "Whi");
		break;
	case IDENT:
		fprintf(f, "Ide");
		break;
	default:
		fprintf(f, "Unk");
		break;
	}
}

int main (int argc, char *argv[])
{
	struct lex_state *cookie = lexer_setup();
	if (cookie == NULL) {
		return 1;
	}
	char data[] = "a11b1b\n1b1b1b1b1a";
	struct Tokens tok;
	for (size_t i = 0; i<sizeof(data)-1; i++) {
		tok = lex_one_char(cookie, data[i]);
		printf("OUTPUT(%s): ", print_char(data[i]));
		print_token(tok.first, stdout);
		printf(" ");
		print_token(tok.second, stdout);
		printf("\n");
	}
	tok = lex_one_char(cookie, EOF);
	printf("OUTPUT(%s): ", print_char(EOF));
	print_token(tok.first, stdout);
	printf(" ");
	print_token(tok.second, stdout);
	printf("\n");
	if (!lexer_destroy(cookie)) {
		return 1;
	}
	return 0;
	(void)argc;
	(void)argv;
}

int yywrap (yyscan_t yyscanner) {
	// Only ever process one file so we return 1 (to stop)
	return 1;
	(void)yyscanner;
}

%}

%option yylineno
%option noinput
%option nounput
%option always-interactive

%%

[1-9][0-9]* { return NUMBER; }
[ \t]     { return WHITESPACE; }
[a-z][a-zA-Z]* { return IDENT; }
<<EOF>> { return 0;}

%%