#include "jni_Lexer.h"
#include "test.c"
#include "test.h"

struct lex_state *cookie = NULL;

/*
 * Class:     jni_Lexer
 * Method:    create
 * Signature: ()Ljni/Lexer;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_create
        (JNIEnv *env, jclass lexerClass) {
    if (cookie != NULL) {
        // throw IllegalStateException
        jclass exceptionClass = (*env)->FindClass(env, "java/lang/IllegalStateException");
        (*env)->ThrowNew(env, exceptionClass, "Lexer already created");
        return NULL;
    }

    cookie = lexer_setup();
    // Create a new Lexer object
    jmethodID constructor = (*env)->GetMethodID(env, lexerClass, "<init>", "()V");
    jobject lexer = (*env)->NewObject(env, lexerClass, constructor);

    return lexer;
};

/*
 * Class:     jni_Lexer
 * Method:    close
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_jni_Lexer_close
        (JNIEnv *env, jobject jobj) {
    lex_one_char(cookie, EOF);
    lexer_destroy(cookie);
    cookie = NULL;
};

/*
 * Class:     jni_Lexer
 * Method:    internalLex
 * Signature: (Ljava/lang/String;)Ljni/Token;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_lex
        (JNIEnv *env, jobject obj, jchar jchar){
    char c = (char) jchar;
    struct Tokens tokens = lex_one_char(cookie, c);

    // Find the Tokens class
    jclass tokensClass = (*env)->FindClass(env, "jni/Tokens");

    // Find the constructor that takes two integers
    jmethodID constructor = (*env)->GetMethodID(env, tokensClass, "<init>", "(II)V");

    // Create a new Tokens object
    jobject token = (*env)->NewObject(env, tokensClass, constructor, tokens.first, tokens.second);

    return token;
};