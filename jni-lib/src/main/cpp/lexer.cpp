#include "jni_Lexer.h"
#include "lex.yy.c"
#include <sstream>
#include <streambuf>
#include <iostream>
//#include <pthread.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <fstream>

bool locked = false;
bool stopped = false;
bool ready = false;
int token = -1;


JNIEXPORT void JNICALL Java_jni_Lexer_run
  (JNIEnv *env, jobject obj){
    printf("Java_jni_Lexer_run");

    // Step 1: Allocate a buffer
    while (!stopped) {
        if (!mkfifo("/tmp/lex", 0666)) {
            perror("mkfifo failed");
            return;
        }

        printf("Created Pipe");

        yyin = fopen("/tmp/lex", "r");

        printf("Running lexer\n");
        ready = true;

        // change ready on lexer_obj
        jclass cls = env->GetObjectClass(obj);
        jfieldID field = env->GetFieldID(cls, "ready", "Z");
        env->SetBooleanField(obj, field, ready);

        // Run the lexer
        token = yylex();

        ready = false;
        // change ready on lexer_obj
        env->SetBooleanField(obj, field, ready);

        fclose(yyin);
    }

    return;
}

/*
 * Class:     dev_rvr_lexerlearning_lexer_Lexer
 * Method:    lex
 * Signature: (Ljava/lang/String;)Ljava/lang/String;
 */
//JNIEXPORT jobject JNICALL Java_jni_Lexer_lex
//        (JNIEnv *env, jobject obj, jstring javaString) {
//
//    const char *nativeString = env->GetStringUTFChars(javaString, 0);
//
//    std::ofstream file;
//    file.open("/tmp/lex", std::ios::binary);
//    file << nativeString;
//    file.close();
//
//    if (token != -1) {
//        std::stringstream ss;
//        ss << token;
//        std::string token_str = ss.str();
//        // create Integer object
//        jclass integerClass = env->FindClass("java/lang/Integer");
//        jmethodID constructor = env->GetMethodID(integerClass, "<init>", "(Ljava/lang/String;)V");
//        jobject token_obj = env->NewObject(integerClass, constructor, token);
//        token = -1;
//        return token_obj;
//    }
//
//    return nullptr;
//};

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

    return obj;
};

/*
 * Class:     jni_Lexer
 * Method:    currentToken
 * Signature: ()Ljni/Token;
 */
JNIEXPORT jobject JNICALL Java_jni_Lexer_currentToken
        (JNIEnv *env, jobject obj) {

    if (token != -1) {
        std::stringstream ss;
        ss << token;
        std::string token_str = ss.str();
        // create Integer object
        jclass integerClass = env->FindClass("java/lang/Integer");
        jmethodID constructor = env->GetMethodID(integerClass, "<init>", "(Ljava/lang/String;)V");
        jobject token_obj = env->NewObject(integerClass, constructor, token);
        token = -1;
        return token_obj;
    }

    return nullptr;
};

JNIEXPORT void JNICALL Java_jni_Lexer_close
        (JNIEnv *env, jobject obj) {
    stopped = true;
    fclose(yyin);
    yylex_destroy();
    locked = false;
};


