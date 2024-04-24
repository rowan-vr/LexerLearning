package jni;

public class Lexer {
    static {
        if (!LibraryLoader.load(Lexer.class, "lexer"))
            System.loadLibrary("lexer");
    }

    public native static Lexer create();

    public native void close();

    public native Tokens lex(char input);
}