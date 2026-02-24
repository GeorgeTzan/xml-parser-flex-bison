%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int yylex();
void yyerror(const char *s);
extern int yylineno;

typedef struct IDNode {
    char *id;
    int line;
    struct IDNode *next;
} IDNode;

typedef struct RadioIDNode {
    char *id;
    struct RadioIDNode *next;
} RadioIDNode;

typedef struct {
    int has_width;
    int has_height;
    int has_text;
    int has_src;
    int has_count;
} MandatoryTracker;

IDNode *id_list = NULL;
RadioIDNode *current_radio_ids = NULL;
MandatoryTracker current_tracker;
int radio_button_count = 0;
int expected_radio_count = -1;
int current_radio_group_line = 0;
int max_value = -1;
int has_max = 0;
int error_count = 0;
char *deferred_checked_button = NULL;
int deferred_checked_line = 0;
int in_radio_button = 0;

void reset_tracker() {
    memset(&current_tracker, 0, sizeof(MandatoryTracker));
}

void check_mandatory(const char *tag_name, int type) {
    if (!current_tracker.has_width) {
        fprintf(stderr, "ERROR (Line %d): Missing mandatory attribute 'android:layout_width' in <%s>\n", yylineno, tag_name);
        error_count++;
    }
    if (!current_tracker.has_height) {
        fprintf(stderr, "ERROR (Line %d): Missing mandatory attribute 'android:layout_height' in <%s>\n", yylineno, tag_name);
        error_count++;
    }
    
    if (type == 1) { // TextView, Button, RadioButton
        if (!current_tracker.has_text) {
            fprintf(stderr, "ERROR (Line %d): Missing mandatory attribute 'android:text' in <%s>\n", yylineno, tag_name);
            error_count++;
        }
    } else if (type == 2) { // ImageView
        if (!current_tracker.has_src) {
            fprintf(stderr, "ERROR (Line %d): Missing mandatory attribute 'android:src' in <%s>\n", yylineno, tag_name);
            error_count++;
        }
    } else if (type == 3) { // RadioGroup
        if (!current_tracker.has_count) {
            fprintf(stderr, "ERROR (Line %d): Missing mandatory attribute 'android:radioButtonCount' in <%s>\n", yylineno, tag_name);
            error_count++;
        }
    }
}

void add_id(const char *id, int line) {
    IDNode *current = id_list;
    while (current != NULL) {
        if (strcmp(current->id, id) == 0) {
            fprintf(stderr, "ERROR (Line %d): Duplicate android:id '%s' (previously defined at line %d)\n", 
                    line, id, current->line);
            error_count++;
            return;
        }
        current = current->next;
    }
    
    IDNode *new_node = malloc(sizeof(IDNode));
    new_node->id = strdup(id);
    new_node->line = line;
    new_node->next = id_list;
    id_list = new_node;
}

int validate_dimension(const char *value) {
    char *val = strdup(value);
    if (val[0] == '"' && val[strlen(val)-1] == '"') {
        val[strlen(val)-1] = '\0';
        memmove(val, val+1, strlen(val));
    }
    
    if (strcmp(val, "wrap_content") == 0 || strcmp(val, "match_parent") == 0) {
        free(val);
        return 1;
    }
    
    for (int i = 0; val[i]; i++) {
        if (!isdigit(val[i])) {
            free(val);
            return 0;
        }
    }
    
    int num = atoi(val);
    free(val);
    return num > 0;
}

int validate_padding(int value) {
    return value > 0;
}

void add_radio_id(const char *id) {
    char *clean_id = strdup(id);
    if (clean_id[0] == '"' && clean_id[strlen(clean_id)-1] == '"') {
        clean_id[strlen(clean_id)-1] = '\0';
        memmove(clean_id, clean_id+1, strlen(clean_id));
    }
    
    RadioIDNode *new_node = malloc(sizeof(RadioIDNode));
    new_node->id = clean_id;
    new_node->next = current_radio_ids;
    current_radio_ids = new_node;
}

int check_radio_id_exists(const char *id) {
    RadioIDNode *current = current_radio_ids;
    while (current != NULL) {
        if (strcmp(current->id, id) == 0) {
            return 1;
        }
        current = current->next;
    }
    return 0;
}

void reset_radio_context() {
    while (current_radio_ids != NULL) {
        RadioIDNode *temp = current_radio_ids;
        current_radio_ids = current_radio_ids->next;
        free(temp->id);
        free(temp);
    }
    radio_button_count = 0;
    expected_radio_count = -1;
    has_max = 0;
    max_value = -1;
}

void check_radio_count() {
    if (deferred_checked_button != NULL) {
        if (!check_radio_id_exists(deferred_checked_button)) {
            fprintf(stderr, "ERROR (Line %d): android:checkedButton references non-existent id '%s'\n", 
                    deferred_checked_line, deferred_checked_button);
            error_count++;
        }
        free(deferred_checked_button);
        deferred_checked_button = NULL;
    }
    
    if (expected_radio_count != -1 && radio_button_count != expected_radio_count) {
        fprintf(stderr, "ERROR (Line %d): RadioGroup expected %d RadioButton(s) but found %d\n",
                current_radio_group_line, expected_radio_count, radio_button_count);
        error_count++;
    }
}

void check_progress_range(int progress) {
    if (has_max && (progress < 0 || progress > max_value)) {
        fprintf(stderr, "ERROR (Line %d): android:progress value %d is not in range [0, %d]\n",
                yylineno, progress, max_value);
        error_count++;
    }
}

%}

%union {
    char *str;
    int num;
}

%token LTAG RTAG TVTAG IVTAG BTAG RGTAG RBTAG PBTAG
%token LCLOSE RCLOSE RGCLOSE
%token AWIDTH AHEIGHT AID ATEXT ASRC APADDING ACOLOR AMAX APROGRESS ACHECKED AORIENT
%token ACOUNT
%token SELFCLOSE GT EQ
%token <str> VALUE
%token <num> NUM

%%

xml     : root
        | xml root
        ;

root    : linear_layout
        | relative_layout
        ;

ll_start: LTAG { reset_tracker(); } attrs { check_mandatory("LinearLayout", 0); } ;
rl_start: RTAG { reset_tracker(); } attrs { check_mandatory("RelativeLayout", 0); } ;
tv_start: TVTAG { reset_tracker(); } attrs { check_mandatory("TextView", 1); } ;
iv_start: IVTAG { reset_tracker(); } attrs { check_mandatory("ImageView", 2); } ;
b_start: BTAG { reset_tracker(); } attrs { check_mandatory("Button", 1); } ;
rg_start: RGTAG { reset_tracker(); current_radio_group_line = yylineno; } attrs { check_mandatory("RadioGroup", 3); } ;
pb_start: PBTAG { reset_tracker(); } attrs { check_mandatory("ProgressBar", 4); } ;
rb_start: RBTAG { reset_tracker(); in_radio_button = 1; } attrs { check_mandatory("RadioButton", 1); } ;

linear_layout
        : ll_start GT contents LCLOSE
        | ll_start SELFCLOSE
        ;

relative_layout
        : rl_start GT contents RCLOSE
        | rl_start GT RCLOSE
        | rl_start SELFCLOSE
        ;

contents: /* empty */
        | contents child
        ;

child   : linear_layout
        | relative_layout
        | tv_start SELFCLOSE
        | iv_start SELFCLOSE
        | b_start SELFCLOSE
        | rg_start GT rbuttons RGCLOSE 
          { check_radio_count(); reset_radio_context(); }
        | pb_start SELFCLOSE { has_max = 0; max_value = -1; }
        ;

rbuttons: rb_start SELFCLOSE { radio_button_count++; in_radio_button = 0; }
        | rbuttons rb_start SELFCLOSE { radio_button_count++; in_radio_button = 0; }
        ;

attrs   : /* empty */
        | attrs attr
        ;

attr    : AWIDTH EQ VALUE { 
            current_tracker.has_width = 1;
            if (!validate_dimension($3)) {
                fprintf(stderr, "ERROR (Line %d): Invalid android:layout_width value %s\n", yylineno, $3);
                error_count++;
            }
          }
        | AHEIGHT EQ VALUE {
            current_tracker.has_height = 1;
            if (!validate_dimension($3)) {
                fprintf(stderr, "ERROR (Line %d): Invalid android:layout_height value %s\n", yylineno, $3);
                error_count++;
            }
          }
        | AWIDTH EQ NUM {
            current_tracker.has_width = 1;
            if ($3 <= 0) {
                fprintf(stderr, "ERROR (Line %d): android:layout_width must be positive, got %d\n", yylineno, $3);
                error_count++;
            }
          }
        | AHEIGHT EQ NUM {
            current_tracker.has_height = 1;
            if ($3 <= 0) {
                fprintf(stderr, "ERROR (Line %d): android:layout_height must be positive, got %d\n", yylineno, $3);
                error_count++;
            }
          }
        | AID EQ VALUE { 
            add_id($3, yylineno);
            if (in_radio_button) {
                add_radio_id($3);
            }
          }
        | ATEXT EQ VALUE { current_tracker.has_text = 1; }
        | ASRC EQ VALUE { current_tracker.has_src = 1; }
        | APADDING EQ NUM {
            if (!validate_padding($3)) {
                fprintf(stderr, "ERROR (Line %d): android:padding must be positive, got %d\n", yylineno, $3);
                error_count++;
            }
          }
        | APADDING EQ VALUE {
            char *val = strdup($3);
            if (val[0] == '"') {
                val[strlen(val)-1] = '\0';
                memmove(val, val+1, strlen(val));
            }
            int num = atoi(val);
            free(val);
            if (num <= 0) {
                fprintf(stderr, "ERROR (Line %d): android:padding must be positive\n", yylineno);
                error_count++;
            }
          }
        | ACOLOR EQ VALUE
        | AMAX EQ NUM { 
            max_value = $3; 
            has_max = 1;
          }
        | AMAX EQ VALUE {
            char *val = strdup($3);
            if (val[0] == '"') {
                val[strlen(val)-1] = '\0';
                memmove(val, val+1, strlen(val));
            }
            max_value = atoi(val);
            has_max = 1;
            free(val);
          }
        | APROGRESS EQ NUM {
            check_progress_range($3);
          }
        | APROGRESS EQ VALUE {
            char *val = strdup($3);
            if (val[0] == '"') {
                val[strlen(val)-1] = '\0';
                memmove(val, val+1, strlen(val));
            }
            int prog = atoi(val);
            free(val);
            check_progress_range(prog);
          }
        | ACHECKED EQ VALUE {
            if (deferred_checked_button != NULL) {
                free(deferred_checked_button);
            }
            deferred_checked_button = strdup($3);
            if (deferred_checked_button[0] == '"' && deferred_checked_button[strlen(deferred_checked_button)-1] == '"') {
                deferred_checked_button[strlen(deferred_checked_button)-1] = '\0';
                memmove(deferred_checked_button, deferred_checked_button+1, strlen(deferred_checked_button));
            }
            deferred_checked_line = yylineno;
          }
        | AORIENT EQ VALUE
        | ACOUNT EQ NUM {
            current_tracker.has_count = 1;
            expected_radio_count = $3;
            if ($3 <= 0) {
                fprintf(stderr, "ERROR (Line %d): android:radioButtonCount must be positive\n", yylineno);
                error_count++;
            }
          }
        | ACOUNT EQ VALUE {
            current_tracker.has_count = 1;
            char *val = strdup($3);
            if (val[0] == '"') {
                val[strlen(val)-1] = '\0';
                memmove(val, val+1, strlen(val));
            }
            expected_radio_count = atoi(val);
            free(val);
            if (expected_radio_count <= 0) {
                fprintf(stderr, "ERROR (Line %d): android:radioButtonCount must be positive\n", yylineno);
                error_count++;
            }
          }
        ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error at line %d: %s\n", yylineno, s);
    error_count++;
}

int main(int argc, char *argv[]) {
    extern FILE *yyin;
    FILE *f;
    
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return 1;
    }
    
    f = fopen(argv[1], "r");
    if (!f) {
        fprintf(stderr, "Cannot open %s\n", argv[1]);
        return 1;
    }
    
    yyin = f;
    
    printf("=== XML File Content ===\n");
    char buf[1024];
    rewind(f);
    int ln = 1;
    while (fgets(buf, sizeof(buf), f)) {
        printf("%3d: %s", ln++, buf);
    }
    printf("========================\n\n");
    
    rewind(f);
    yyin = f;
    
    int result = yyparse();
    fclose(f);
    
    while (id_list != NULL) {
        IDNode *temp = id_list;
        id_list = id_list->next;
        free(temp->id);
        free(temp);
    }
    
    if (result == 0 && error_count == 0) {
        printf("\n[OK] XML file is valid (syntax and semantics)!\n");
        return 0;
    } else {
        printf("\n[ERROR] XML file contains %d error(s)!\n", error_count + (result != 0 ? 1 : 0));
        return 1;
    }
}
