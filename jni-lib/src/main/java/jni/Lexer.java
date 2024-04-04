package jni;

import java.io.*;
import java.util.concurrent.CompletableFuture;

public class Lexer {
    static {
        if (!LibraryLoader.load(Lexer.class, "lexer"))
            System.loadLibrary("lexer");
    }
    public native static Lexer create();

    public native void close();

    public native void run();

    public CompletableFuture<Void> runAsync() {
        return CompletableFuture.runAsync(this::run);
    }

    private boolean terminated = false;
    private boolean ready = false;

    void waitReady() {
        while (!ready) {
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public int lex(String input){
        if (terminated)
            throw new IllegalStateException("Lexer is terminated!");

        if (!ready)
            throw new IllegalStateException("Lexer is not ready!");


        File file = new File("/tmp/lex");
        // write input to file

        try {
            OutputStream os = new FileOutputStream(file);
            os.write(input.getBytes());
            os.close();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return 0;
    }

    public native Integer currentToken();

    public boolean isTerminated() {
        return terminated;
    }
}
