%{
#include <stdio.h>
#include <stdbool.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>

#define WAIT_FOR_LEXER_MS 25
#define POLL_BUFFER_MS (WAIT_FOR_LEXER_MS/10)
#define LEX_BUFFER_SIZE 1024

// From test.h
extern int yylex_init (yyscan_t* scanner);
extern int yylex_destroy ( yyscan_t yyscanner );
extern int yylex (yyscan_t yyscanner);
extern void yyset_in  ( FILE * _in_str , yyscan_t yyscanner );

#define ms2ns(ms) ((ms)*1000*1000)

enum Token {
	ERROR = -1,
	NOTOKEN = 1,
	NUMBER = 2,
	WHITESPACE = 3,
	IDENT = 4,
	NOT_NOT = 11,
	NOT_NUM = 12,
	NOT_WHI = 13,
	NOT_IDE = 13,
	NUM_NOT = 21,
	NUM_NUM = 22,
	NUM_WHI = 23,
	NUM_IDE = 23,
	WHI_NOT = 21,
	WHI_NUM = 22,
	WHI_WHI = 23,
	WHI_IDE = 23,
	IDE_NOT = 21,
	IDE_NUM = 22,
	IDE_WHI = 23,
	IDE_IDE = 23,
};

char *tokenNames[] =
	{ [NOTOKEN] = "No token"
	, [NUMBER] = "Number"
	, [WHITESPACE] = "Whitespace"
	, [IDENT] = "Ident"
	};

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
	struct lex_state *cookie = (struct lex_state *)vargp;
	yyscan_t yyscanner;
	yylex_init(&yyscanner);
	yyset_in(cookie->fhandle, yyscanner);
	enum Token tok;
	while ((tok = yylex(yyscanner)) != 0) {
		cookie->tbuf[(cookie->tend++) % LEX_BUFFER_SIZE] = tok;
	}
	yylex_destroy(yyscanner);
	return vargp;
}

ssize_t bi_read(void *cookie_vp, char *buf, size_t size)
{
	struct lex_state *cookie = (struct lex_state *)cookie_vp;

	// This blocks until there is data
	while (size > 0 && cookie->cstart == cookie->cend) {
		const struct timespec req = {.tv_sec=0, .tv_nsec=ms2ns(POLL_BUFFER_MS)};
		if (nanosleep(&req, NULL) != 0) {
			perror("nanosleep");
			return -1;
		}
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
	return numread;
}

enum Token lex_one_char(struct lex_state *cookie, int c)
{
	// Put character in buffer
	cookie->cbuf[(cookie->cend++) % LEX_BUFFER_SIZE] = c;

	const struct timespec req = {.tv_sec=0, .tv_nsec=ms2ns(WAIT_FOR_LEXER_MS)};
	if (nanosleep(&req, NULL) != 0) {
		perror("nanosleep");
		return -1;
	}

	enum Token res = NOTOKEN;
	switch (cookie->tend - cookie->tstart) {
	case 0:
		break;
	case 1:
		res = cookie->tbuf[cookie->tstart++];
		break;
	case 2:
		res = cookie->tbuf[cookie->tstart++];
		res += 10*cookie->tbuf[cookie->tstart++];
		break;
	default:
		fprintf(stderr, "lexer pushed three tokens or more?\n");
		res = -1;
		break;
	}
	return res;
}

struct lex_state *lexer_setup()
{
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
	if (pthread_create(&buf->thread, NULL, lexerThread, buf) != 0) {
		perror("pthread_create");
		return NULL;
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
			if (pthread_kill(buf->thread, SIGINT) != 0) {
				perror("pthread_kill");
				return false;
			}
		} else {
			perror("pthread_timedjoin_np");
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

int main (int argc, char *argv[])
{
	struct lex_state *cookie = lexer_setup();
	if (cookie == NULL) {
		return 1;
	}
	char data[] = "abc\n123a";
	for (size_t i = 0; i<sizeof(data)-1; i++) {
		printf("lex_one_char(%c): %d\n", data[i],
			lex_one_char(cookie, data[i]));
	}
	printf("lex_one_char(EOF): %d\n", lex_one_char(cookie, EOF));
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