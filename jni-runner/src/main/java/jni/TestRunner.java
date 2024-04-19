package jni;

public class TestRunner {
    public static void main(String[] args) {
        Lexer lexer = Lexer.create();
        System.out.println("Lexer: " + lexer);
        String input = "a1a";
        for (int i = 0; i < input.length(); i++) {
            char symbol = input.charAt(i);
            int token = lexer.lex(symbol);
            System.out.println("Symbol: " + symbol + " Token: " + token);
        }
        int token = lexer.lex((char) -1);
        System.out.println("Symbol: EOF Token: " + token);
        lexer.close();
    }
}
