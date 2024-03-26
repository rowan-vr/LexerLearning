#include "jni_Lexer.h"
#include "lex.yy.c"
#include <sstream>
#include <streambuf>
#include <iostream>



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
JNIEXPORT jobject JNICALL Java_jni_Lexer_lex
        (JNIEnv *env, jobject obj, jstring javaString, jboolean jshouldTerminate) {
    if (jshouldTerminate == JNI_TRUE) {
        should_terminate = 1;
    } else {
        should_terminate = 0;
    }

    const char *nativeString = env->GetStringUTFChars(javaString, 0);
    yyin = fmemopen((void *) nativeString, strlen(nativeString), "r");
//    std::string str(nativeString);
//    str.push_back('\0'); // add null character at the end
//    if (fputs(str.c_str(), yyin) == EOF) {
//        perror("fputs failed");
//        return nullptr;
//    }

    const int lex_ret = yylex();

    fclose(yyin);


    if (lex_ret == 0) {
        // Set the ended true if the lexer has ended on the obj
        jclass cls = env->GetObjectClass(obj);
        jfieldID endedField = env->GetFieldID(cls, "terminated", "Z");
        env->SetBooleanField(obj, endedField, true);
    }

    // check if current token is defined
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

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    create
 * Signature: ()Ldev/rvr/lexerlearning/lexer/Lexer;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_create
        (JNIEnv *env, jclass cls) {
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

