package jni;

public class Lexer {
    static {
        if (!LibraryLoader.load(Lexer.class, "lexer"))
            System.loadLibrary("lexer");
    }
    public native static Lexer create();

    private boolean terminated = false;

    public native Token lex(String input, boolean shouldTerminate);

    public native Token currentToken();

    public boolean isTerminated() {
        return terminated;
    }
}
