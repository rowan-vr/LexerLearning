package jni;

public class TestRunner {
    public static void main(String[] args) {
        Lexer lexer = Lexer.create();
        System.out.println("Lexer: " + lexer);
        System.out.println(lexer.lex("c"));
        System.out.println(lexer.lex("o"));
        System.out.println(lexer.lex("m"));
        System.out.println(lexer.lex("m"));
        System.out.println(lexer.lex(":"));
        System.out.println(lexer.lex("\n"));
        System.out.println(lexer.lex("a"));
        lexer.close();
    }
}
