
#include <jni.h>
#include <unistd.h>
#include <ctype.h>
#include <string.h>

#include "hiddata.h"
#include "linkm-lib.h"
#include "linkmbootload-lib.h"

/* ------------------------------------------------------------------------- */

static usbDevice_t* dev = NULL;   // sigh.

// the goal is to have a usbDevice_t* per LinkM instance, 
// but for some reason I cannot get a LinkM instance int or long to
// store the pointer in and then retrieve it. 
// So for now, there's one global 'dev', so only one LinkM per system.

// maybe one way to support multiple LinkMs per system is to have 
// small array of devs (e.g "dev[8]") and then allow up to 8 devs
// BUT, also need to change C API to support more advanced query & finding
// of LinkMs.

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

JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_commandmany
(JNIEnv *env, jobject obj, jint cmd, jint cmd_count, jint cmd_len, jbyteArray jb_send)
{
    int err=0,i;
    uint8_t cmdbyte = (uint8_t) cmd;
    int num_send=0;
    uint8_t* byte_send = NULL;
    uint8_t* byte_sendp;

    if( jb_send != NULL ) {
        num_send = (*env)->GetArrayLength(env, jb_send );
        byte_send = (uint8_t*)(*env)->GetByteArrayElements(env, jb_send,0);
    }
    
    //err = linkm_command(dev, cmdbyte, num_send,num_recv, byte_send,byte_recv);
    for( i=0; i< cmd_count; i++) {
        byte_sendp = byte_send + (cmd_count*i);
        err += linkm_command(dev, cmdbyte, cmd_len,0, byte_sendp,0);
        // FIXME: need delay here?
    }

    if( err ) {
        (*env)->ExceptionDescribe(env);          // throw an exception.
        (*env)->ExceptionClear(env);
        jclass newExcCls = (*env)->FindClass(env,"java/io/IOException");
        (*env)->ThrowNew(env, newExcCls, linkm_error_msg(err));
    }
    
    if( jb_send != NULL )
        (*env)->ReleaseByteArrayElements(env, jb_send, (jbyte*) byte_send, 0);

}


// ----------------------------------------------------------------------------

/*
 *
 */
JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_bootload
(JNIEnv *env, jobject obj, jstring filename, jboolean reset)
{
    int err=0;
    char* errmsg = NULL;
    const char *fileutf;
    // Convert to UTF8 
    if( filename == NULL ) {
        errmsg = "must give filename";
    }
    else { 
        fileutf = (*env)->GetStringUTFChars(env, filename, JNI_FALSE);

        err = linkmboot_uploadFromFile(fileutf, reset);
        if( err == -1 ) {
            errmsg = "bad upload";
        }
        if( err == -2 ) {
            errmsg = "No data in input file";
        }
        else if( err == -3 ) { 
            errmsg = "error uploading";
        }

        // release created UTF string
        (*env)->ReleaseStringUTFChars(env, filename, fileutf);
    }

    if( err ) {
        (*env)->ExceptionDescribe(env);          // throw an exception.
        (*env)->ExceptionClear(env);
        jclass newExcCls = (*env)->FindClass(env,"java/io/IOException");
        (*env)->ThrowNew(env, newExcCls, errmsg);
    }

}

/*
 *
 */
JNIEXPORT void JNICALL Java_thingm_linkm_LinkM_bootloadReset
(JNIEnv *env, jobject obj)
{
    int err=0;
    
    err = linkmboot_reset();

    if( err ) {
        (*env)->ExceptionDescribe(env);          // throw an exception.
        (*env)->ExceptionClear(env);
        jclass newExcCls = (*env)->FindClass(env,"java/io/IOException");
        (*env)->ThrowNew(env, newExcCls, linkm_error_msg(err));
    }
}

/*
 //what is wrong with this?
    jclass cls = (*env)->GetObjectClass(env, obj);
    jfieldID fid = (*env)->GetFieldID(env, cls, "ldev","J");

    dev = (usbDevice_t*) (*env)->GetLongField(env,obj, fid);

*/


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
