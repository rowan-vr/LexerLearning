package jni;

public class Lexer {
    static {
        if (!LibraryLoader.load(Lexer.class, "lexer"))
            System.loadLibrary("lexer");
    }
    public native static Lexer create();

    public native void close();

    private boolean terminated = false;

    public native Token lex(String input);

    public native Token currentToken();

    public boolean isTerminated() {
        return terminated;
    }
}
