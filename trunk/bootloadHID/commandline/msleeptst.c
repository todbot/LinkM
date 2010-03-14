

#include <stdio.h>

#ifdef _MINGW32
#include <windows.h>
#define msleep(m) Sleep(m)
#else
#include <unistd.h>
#define msleep(m) usleep(1000*m)
#endif


// print "hello" every 100 milliseconds
int main(int argc, char **argv)
{
    long milliSec = 100;

    for( int i=0; i<10; i++ ) {
        printf("hello\n"); fflush(stdout);
        msleep(milliSec);
    }
    printf("goodbye\n");

}


    //struct timespec t;
    //struct timespec t = { 3/*seconds*/, 0/*nanoseconds*/};
    //t.tv_sec = 1;
    //t.tv_nsec = 4*500000000; // Five hundred million nanoseconds is half second.
    //nanosleep(&t, NULL); /* Ignore remainder. */
    //usleep(milliSec*1000); //microseconds

/*
//#include <sys/select.h>
int my_usleep(long usec)
{
    struct timeval tv;
    tv.tv_sec = usec/1000000L;
    tv.tv_usec = usec%1000000L;
    return select(0, 0, 0, 0, &tv);
}
*/
