%%
ping	printf("%s\n", "pong");
%%

int yywrap(void) {
    return 1;
}