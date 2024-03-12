#include "dev_rvr_lexerlearning_lexer_Lexer.h"

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    lex
 * Signature: (Ljava/lang/String;)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_dev_rvr_lexerlearning_lexer_Lexer_lex
  (JNIEnv *env, jobject, jstring) {
    return env->NewStringUTF("Hello from C++");
};

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    create
 * Signature: ()Ldev/rvr/lexerlearning/lexer/Lexer;
 */
JNIEXPORT jobject JNICALL Java_dev_rvr_lexerlearning_lexer_Lexer_create
  (JNIEnv *env, jclass) {
    jclass cls = env->FindClass("dev/rvr/lexerlearning/lexer/Lexer");
    jmethodID constructor = env->GetMethodID(cls, "<init>", "()V");
    jobject obj = env->NewObject(cls, constructor);
    return obj;
};