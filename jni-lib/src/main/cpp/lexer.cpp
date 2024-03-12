#include "jni_Lexer.h"
#include "lex.yy.c"
#include <sstream>
#include <streambuf>
#include <iostream>

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    lex
 * Signature: (Ljava/lang/String;)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_jni_Lexer_lex
  (JNIEnv *env, jobject obj, jstring javaString) {
    const char *nativeString = env->GetStringUTFChars(javaString, 0);
    yyin = fmemopen((void*)nativeString, strlen(nativeString), "r");

    // Redirect std::cout to a stringstream
    std::stringstream buffer;
    std::streambuf *old = std::cout.rdbuf(buffer.rdbuf());

    // Run the lexer
    yylex();

    // Clean up
    std::cout.rdbuf(old);
    fclose(yyin);

    // Return the result
    std::string output = buffer.str();

    return env->NewStringUTF(output.c_str());
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
    return obj;
};