typedef void * histdata_t;
typedef struct _hist_entry {
    char *line;
    char *timestamp;
    histdata_t data;
}HIST_ENTRY;
typedef struct _hist_state {
    HIST_ENTRY **entries;
    int offset;
    int length;
    int size;
    int flags;
} HISTORY_STATE;
HIST_ENTRY _lastentry;
HISTORY_STATE _laststate;
