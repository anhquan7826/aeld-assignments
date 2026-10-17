#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <libgen.h>
#include <sys/stat.h>
#include <syslog.h>

int main(int argc, char* argv[]) {
    openlog("writer", LOG_CONS | LOG_PID, LOG_USER);
    int result = 0;
    if (argc < 3) {
        syslog(LOG_ERR, "Invalid argument!");
        return 1;
    }
    char* writefile = argv[1];
    char* writestr = argv[2];
    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Cannot create file!");
        result = 1;
        return result;
    }
    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);
    fprintf(file, "%s", writestr);
    fclose(file);
    closelog();
    return result;
}