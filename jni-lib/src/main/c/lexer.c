#include "jni_Lexer.h"
#include "test.c"
#include "test.h"

struct lex_state *cookie;

/*
 * Class:     jni_Lexer
 * Method:    create
 * Signature: ()Ljni/Lexer;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_create
        (JNIEnv *env, jclass lexerClass) {
    cookie = lexer_setup();
    // Create a new Lexer object
    jmethodID constructor = (*env)->GetMethodID(env, lexerClass, "<init>", "()V");
    jobject lexer = (*env)->NewObject(env, lexerClass, constructor);
    printf("created lexer");

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
};

/*
 * Class:     jni_Lexer
 * Method:    internalLex
 * Signature: (Ljava/lang/String;)Ljni/Token;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_internalLex
        (JNIEnv *, jobject, jstring) {
    return  NULL;
};

/*
 * Class:     jni_Lexer
 * Method:    currentToken
 * Signature: ()Ljni/Token;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_currentToken
        (JNIEnv *, jobject)
{
    return NULL;
};