package jni;

public class Lexer {
    static {
        if (!LibraryLoader.load(Lexer.class, "lexer"))
            System.loadLibrary("lexer");
    }
    public native static Lexer create();

    public native void close();

    private boolean terminated = false;

    private StringBuffer input = new StringBuffer();

    public Token lex(String input) {
        this.input.append(input);
        Token token = internalLex(this.input.toString());
        return token;
    }

    private native Token internalLex(String input);

    public native Token currentToken();

    public boolean isTerminated() {
        return terminated;
    }
}