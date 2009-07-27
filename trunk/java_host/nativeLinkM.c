
#include <jni.h>
#include <unistd.h>
#include <ctype.h>
#include <string.h>

#include "hiddata.h"
#include "linkm-lib.h"


/* ------------------------------------------------------------------------- */
static usbDevice_t* dev;   // sigh.

/**
 * Class:     LinkM
 * Method:    debug
 * Signature: (Z)V
 */
JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_linkmdebug
(JNIEnv *env, jobject obj, jint d)
{
    linkm_debug = d;
}

/**
 *
 */
JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_open
(JNIEnv *env, jobject obj, jint vid, jint pid, jstring vstr, jstring pstr)
{
    int err;
    
    // open up linkm, get back a 'dev' to pass around
    if( (err = linkm_open( &dev )) ) {  // FIXME: pass in vid/pid in the future
        //printf("Error opening LinkM: %s\n", linkm_error_msg(err));
        (*env)->ExceptionDescribe(env);          // throw an exception.
        (*env)->ExceptionClear(env);
        jclass newExcCls = (*env)->FindClass(env,"java/io/IOException");
        (*env)->ThrowNew(env, newExcCls, linkm_error_msg(err));
    }
    // otherwise we're good to go
}

/**
 *
 */
JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_close
(JNIEnv *env, jobject obj)
{
    linkm_close(dev);
}

/**
 *
 */
JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_command
(JNIEnv *env, jobject obj, jint cmd, jbyteArray jb_send, jbyteArray jb_recv)
{
    int err;
    uint8_t cmdbyte = (uint8_t) cmd;
    int num_send=0;
    int num_recv=0;
    uint8_t* byte_send = NULL;
    uint8_t* byte_recv = NULL;

    if( jb_send != NULL ) {
        num_send = (*env)->GetArrayLength(env, jb_send );
        byte_send = (uint8_t*)(*env)->GetByteArrayElements(env, jb_send,0);
    }
    if( jb_recv != NULL ) {
        num_recv = (*env)->GetArrayLength(env, jb_recv );
        byte_recv = (uint8_t*)(*env)->GetByteArrayElements(env, jb_recv,0);
    }

    /*
    printf("cmd: num_send:%d num_recv:%d\n",num_send,num_recv);
    printf("cmd: 0x%02x byte_send: ",cmdbyte);
    for( int i=0; i<num_send; i++ )
        printf("0x%02x ",byte_send[i]);
    printf("\n");
    */

    err = linkm_command(dev, cmdbyte, num_send,num_recv, byte_send,byte_recv);
    if( err ) {
        (*env)->ExceptionDescribe(env);          // throw an exception.
        (*env)->ExceptionClear(env);
        jclass newExcCls = (*env)->FindClass(env,"java/io/IOException");
        (*env)->ThrowNew(env, newExcCls, linkm_error_msg(err));
    }
    
    if( jb_send != NULL )
        (*env)->ReleaseByteArrayElements(env, jb_send, (jbyte*) byte_send, 0);
    if( jb_recv != NULL ) 
        (*env)->ReleaseByteArrayElements(env, jb_recv, (jbyte*) byte_recv, 0);
}


/*
 * Class:     LinkM
 * Method:    test
 * Signature: ([B)[B
 */
JNIEXPORT jbyteArray JNICALL Java_thingm_linkm_LinkM_test
(JNIEnv *env, jobject obj, jbyteArray jba)
{

  jbyteArray jbo;
  int jbsize;
  jbyte* ba;
  int i;

  jbsize = (*env)->GetArrayLength(env, jba );
  ba = (jbyte*) (*env)->GetByteArrayElements(env, jba, 0);
  
  jbo = (*env)->NewByteArray(env, jbsize);
  
  for( i=0; i< jbsize; i++ ) {
    ba[i] = toupper( ba[i] );
  }

  (*env)->SetByteArrayRegion(env, jbo, 0, jbsize, (jbyte *)ba );

  return (jbo);

}


/*
 //what is wrong with this?
    jclass cls = (*env)->GetObjectClass(env, obj);
    jfieldID fid = (*env)->GetFieldID(env, cls, "ldev","J");

    dev = (usbDevice_t*) (*env)->GetLongField(env,obj, fid);

*/
