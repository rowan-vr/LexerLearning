package jni;

public class Runner {
    public static void main(String[] args) {
        Lexer lexer = Lexer.create();
        System.out.println("Created lexer");
//        System.out.println(lexer.lex("32 + 8", false));
        System.out.println(lexer.lex(" ", false));
        System.out.println(lexer.lex("2", false));
        System.out.println(lexer.lex(" ", false));
        System.out.println(lexer.lex("+", false));
        System.out.println(lexer.lex(" ", false));
        System.out.println(lexer.lex("2", true));
    }
}