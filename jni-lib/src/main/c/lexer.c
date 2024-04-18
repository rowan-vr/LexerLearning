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

    lexer_destroy(cookie);
    cookie = NULL;
};

/*
 * Class:     jni_Lexer
 * Method:    internalLex
 * Signature: (Ljava/lang/String;)Ljni/Token;
 */
JNIEXPORT jint JNICALL Java_jni_Lexer_lex
        (JNIEnv *env, jobject obj, jchar jchar){
    char c = (char) jchar;
    int token = lex_one_char(cookie, c);
//    printf("(char,token): (%c,%d)\n", c, token);
    return token;
};