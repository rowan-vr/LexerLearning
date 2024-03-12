package jni;

public class Runner {
    public static void main(String[] args) {
        Lexer lexer = Lexer.create();
        System.out.println(lexer.lex("ping"));
    }
}