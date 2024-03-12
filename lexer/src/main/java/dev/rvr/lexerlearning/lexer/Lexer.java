package dev.rvr.lexerlearning.lexer;

public class Lexer {
//    static {
//        System.loadLibrary("lexer");
//    }

    public static void main(String[] args) {
        Lexer.create().lex("1 + 2");
    }

    public native String lex(String input);

    public native static Lexer create();
}