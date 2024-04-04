package jni;

public class TestRunner {
    public static void main(String[] args) {
        Lexer lexer = Lexer.create();
        System.out.println("Lexer: " + lexer);
        lexer.runAsync();
        lexer.waitReady();
//        int out = lexer.lex("t");
//        System.out.println("Lexer.lex(\"t\"): " + out);
//        System.out.println("Current token: " + lexer.currentToken());
//        lexer.close();
    }
}
