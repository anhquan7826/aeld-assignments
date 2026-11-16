#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;

    // Gettting thread data
    struct thread_data *data = (struct thread_data *)thread_param;
    // Sleeping for `wait_to_obtain_ms`
    if (usleep(data->wait_to_obtain_ms) != 0)
    {
        goto fail;
    }
    // Acquiring lock
    if (pthread_mutex_lock(data->mutex) != 0)
    {
        goto fail;
    }
    // Sleeping for `wait_to_release_ms`
    usleep(data->wait_to_release_ms);
    // Releasing lock
    if (pthread_mutex_unlock(data->mutex) != 0)
    {
        goto fail;
    }
    data->thread_complete_success = true;
    goto end;
fail:
    data->thread_complete_success = false;
end:
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    bool result = true;
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data *data = NULL;
    data = calloc(1, sizeof(struct thread_data));
    if (!data)
    {
        result = false;
        goto end;
    }

    data->wait_to_obtain_ms = wait_to_obtain_ms;
    data->wait_to_release_ms = wait_to_release_ms;
    data->mutex = mutex;

    if (pthread_create(thread, NULL, threadfunc, data) != 0)
    {
        result = false;
        goto end;
    }

end:
    return result;
}

