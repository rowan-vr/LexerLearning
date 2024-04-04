#include "jni_Lexer.h"
#include "lex.yy.c"
#include <sstream>
#include <streambuf>
#include <iostream>

bool locked = false;


//void *runLexer(void *arg) {
//    // Step 1: Allocate a buffer
//    size_t bufferSize = 1024; // adjust size as needed
//    char *buffer = new char[bufferSize];
//    // Step 2: Create a FILE* stream
//    yyin = fmemopen(buffer, bufferSize, "a+");
//    if (yyin == NULL) {
//        perror("fmemopen failed");
//        return nullptr;
//    }
//
////    yyin = fmemopen((void*)"", 0, "r");
//
//    // Run the lexer
//    const int lex_ret = yylex();
//
//    fclose(yyin);
//
//    return nullptr;
//}

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    lex
 * Signature: (Ljava/lang/String;)Ljava/lang/String;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_internalLex
        (JNIEnv *env, jobject obj, jstring javaString) {

    const char *nativeString = env->GetStringUTFChars(javaString, 0);
    yyin = fmemopen((void *) nativeString, strlen(nativeString), "r");

    int last_not_eof = 0;
    int last_not_eof_line = 0;
    char* last_not_eof_lexeme = 0;
    int last_token = -1;
    while (last_token != 0) {
        last_token = yylex();
//        printf("Token: %d\n", last_token);
        if (last_token != 0) {
            last_not_eof = last_token;
            last_not_eof_line = yylineno;
            last_not_eof_lexeme = yytext;
        }
    }

    fclose(yyin);

    jclass tokenClass = env->FindClass("jni/Token");
    jmethodID constructor = env->GetMethodID(tokenClass, "<init>", "(ILjava/lang/String;I)V");
    jobject token = env->NewObject(tokenClass, constructor, last_not_eof, env->NewStringUTF(last_not_eof_lexeme), last_not_eof_line);
    return token;

};

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    create
 * Signature: ()Ldev/rvr/lexerlearning/lexer/Lexer;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_create
        (JNIEnv *env, jclass cls) {
    if (locked) {
        jclass exClass = env->FindClass("java/lang/IllegalStateException");
        return reinterpret_cast<jobject>(env->ThrowNew(exClass, "Cannot intialize multiple lexers at once!"));
    }
    locked = true;

    jmethodID constructor = env->GetMethodID(cls, "<init>", "()V");
    jobject obj = env->NewObject(cls, constructor);

    size_t bufferSize = 1024; // adjust size as needed
    char *buffer = new char[bufferSize];
    // Step 2: Create a FILE* stream
    yyin = fmemopen(buffer, bufferSize, "a+");
    if (yyin == NULL) {
        perror("fmemopen failed");
        return nullptr;
    }

    // Create new thread for the lexer
//    pthread_t lexer_thread;
////    const char *nativeString = env->GetStringUTFChars(javaString, 0);
//    pthread_create(&lexer_thread, nullptr, runLexer, nullptr);

    return obj;
};

/*
 * Class:     jni_Lexer
 * Method:    currentToken
 * Signature: ()Ljni/Token;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_currentToken
        (JNIEnv *env, jobject obj) {

    if (current_token_status == PRESENT) {
        // Create new instance of the jni.Token class
        jclass tokenClass = env->FindClass("jni/Token");
        jmethodID constructor = env->GetMethodID(tokenClass, "<init>", "(ILjava/lang/String;I)V");
        jobject token = env->NewObject(tokenClass, constructor, current_token.token, current_token.lexeme,
                                       current_token.line);
        return token;
    }

    return nullptr;
};

JNIEXPORT void JNICALL Java_jni_Lexer_close
        (JNIEnv *env, jobject obj) {
    yylex_destroy();
    locked = false;
};