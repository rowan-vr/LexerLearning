package jni;

public class Lexer {
    static {
        if (!LibraryLoader.load(Lexer.class, "lexer"))
            System.loadLibrary("lexer");
    }

    public native String lex(String input);

    public native static Lexer create();
}
