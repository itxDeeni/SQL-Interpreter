parser grammar MySQLParser;
options {
    superClass = MySQLBaseRecognizer;
    tokenVocab = MySQLLexer;
    exportMacro = PARSERS_PUBLIC_TYPE;
}

@header {
}

createDatabase:
    DATABASE_SYMBOL ifNotExists? schemaName createDatabaseOption*
;

createDatabaseOption:
    defaultCharset
    | defaultCollation
    | {serverVersion >= 80016}? defaultEncryption
;

createTable:
    TEMPORARY_SYMBOL? TABLE_SYMBOL ifNotExists? tableName (
        (OPEN_PAR_SYMBOL tableElementList CLOSE_PAR_SYMBOL)? createTableOptions? partitionClause? duplicateAsQueryExpression?
        | LIKE_SYMBOL tableRef
        | OPEN_PAR_SYMBOL LIKE_SYMBOL tableRef CLOSE_PAR_SYMBOL
    )
;

tableElementList:
    tableElement (COMMA_SYMBOL tableElement)*
;

tableElement:
    columnDefinition
    | tableConstraintDef
;

duplicateAsQueryExpression: (REPLACE_SYMBOL | IGNORE_SYMBOL)? AS_SYMBOL? queryExpressionOrParens
;

queryExpressionOrParens:
    queryExpression
    | queryExpressionParens
;

dropTable:
    TEMPORARY_SYMBOL? type = (TABLE_SYMBOL | TABLES_SYMBOL) ifExists? tableRefList (
        RESTRICT_SYMBOL
        | CASCADE_SYMBOL
    )?
;
insertStatement:
    INSERT_SYMBOL insertLockOption? IGNORE_SYMBOL? INTO_SYMBOL? tableRef usePartition? (
        insertFromConstructor ({ serverVersion >= 80018}? valuesReference)?
        | SET_SYMBOL updateList ({ serverVersion >= 80018}? valuesReference)?
        | insertQueryExpression
    ) insertUpdateList?
;

insertLockOption:
    LOW_PRIORITY_SYMBOL
    | DELAYED_SYMBOL // Only allowed if no select is used. Check in the semantic phase.
    | HIGH_PRIORITY_SYMBOL
;

insertFromConstructor:
    (OPEN_PAR_SYMBOL fields? CLOSE_PAR_SYMBOL)? insertValues
;

fields:
    insertIdentifier (COMMA_SYMBOL insertIdentifier)*
;

insertValues:
    (VALUES_SYMBOL | VALUE_SYMBOL) valueList
;

insertQueryExpression:
    queryExpressionOrParens
    | OPEN_PAR_SYMBOL fields? CLOSE_PAR_SYMBOL queryExpressionOrParens
;
showStatement:
    SHOW_SYMBOL (
        {serverVersion < 50700}? value = AUTHORS_SYMBOL
        | value = DATABASES_SYMBOL likeOrWhere?
        | showCommandType? value = TABLES_SYMBOL inDb? likeOrWhere?
        | FULL_SYMBOL? value = TRIGGERS_SYMBOL inDb? likeOrWhere?
        | value = EVENTS_SYMBOL inDb? likeOrWhere?
        | value = TABLE_SYMBOL STATUS_SYMBOL inDb? likeOrWhere?
        | value = OPEN_SYMBOL TABLES_SYMBOL inDb? likeOrWhere?
        | value = PLUGINS_SYMBOL
        | value = ENGINE_SYMBOL (engineRef | ALL_SYMBOL) (
            STATUS_SYMBOL
            | MUTEX_SYMBOL
            | LOGS_SYMBOL
        )
        | showCommandType? value = COLUMNS_SYMBOL (FROM_SYMBOL | IN_SYMBOL) tableRef inDb? likeOrWhere?
        | (BINARY_SYMBOL | MASTER_SYMBOL) value = LOGS_SYMBOL
        | value = SLAVE_SYMBOL (HOSTS_SYMBOL | STATUS_SYMBOL nonBlocking channel?)
        | value = (BINLOG_SYMBOL | RELAYLOG_SYMBOL) EVENTS_SYMBOL (
            IN_SYMBOL textString
        )? (FROM_SYMBOL ulonglong_number)? limitClause? channel?
        | ({serverVersion >= 80000}? EXTENDED_SYMBOL)? value = (
            INDEX_SYMBOL
            | INDEXES_SYMBOL
            | KEYS_SYMBOL
        ) fromOrIn tableRef inDb? whereClause?
        | STORAGE_SYMBOL? value = ENGINES_SYMBOL
        | COUNT_SYMBOL OPEN_PAR_SYMBOL MULT_OPERATOR CLOSE_PAR_SYMBOL value = (
            WARNINGS_SYMBOL
            | ERRORS_SYMBOL
        )
        | value = WARNINGS_SYMBOL limitClause?
        | value = ERRORS_SYMBOL limitClause?
        | value = PROFILES_SYMBOL
        | value = PROFILE_SYMBOL (profileType (COMMA_SYMBOL profileType)*)? (
            FOR_SYMBOL QUERY_SYMBOL INT_NUMBER
        )? limitClause?
        | optionType? value = (STATUS_SYMBOL | VARIABLES_SYMBOL) likeOrWhere?
        | FULL_SYMBOL? value = PROCESSLIST_SYMBOL
        | charset likeOrWhere?
        | value = COLLATION_SYMBOL likeOrWhere?
        | {serverVersion < 50700}? value = CONTRIBUTORS_SYMBOL
        | value = PRIVILEGES_SYMBOL
        | value = GRANTS_SYMBOL (FOR_SYMBOL user)?
        | value = GRANTS_SYMBOL FOR_SYMBOL user USING_SYMBOL userList
        | value = MASTER_SYMBOL STATUS_SYMBOL
        | value = CREATE_SYMBOL (
            object = DATABASE_SYMBOL ifNotExists? schemaRef
            | object = EVENT_SYMBOL eventRef
            | object = FUNCTION_SYMBOL functionRef
            | object = PROCEDURE_SYMBOL procedureRef
            | object = TABLE_SYMBOL tableRef
            | object = TRIGGER_SYMBOL triggerRef
            | object = VIEW_SYMBOL viewRef
            | {serverVersion >= 50704}? object = USER_SYMBOL user
        )
        | value = PROCEDURE_SYMBOL STATUS_SYMBOL likeOrWhere?
        | value = FUNCTION_SYMBOL STATUS_SYMBOL likeOrWhere?
        | value = PROCEDURE_SYMBOL CODE_SYMBOL procedureRef
        | value = FUNCTION_SYMBOL CODE_SYMBOL functionRef
    )
;

showCommandType:
    FULL_SYMBOL
    | {serverVersion >= 80000}? EXTENDED_SYMBOL FULL_SYMBOL?
;

nonBlocking:
    {serverVersion >= 50700 && serverVersion < 50706}? NONBLOCKING_SYMBOL?
    | /* empty */
;

fromOrIn:
    FROM_SYMBOL
    | IN_SYMBOL
;

inDb:
    fromOrIn identifier
;

profileType:
    BLOCK_SYMBOL IO_SYMBOL
    | CONTEXT_SYMBOL SWITCHES_SYMBOL
    | PAGE_SYMBOL FAULTS_SYMBOL
    | (
        ALL_SYMBOL
        | CPU_SYMBOL
        | IPC_SYMBOL
        | MEMORY_SYMBOL
        | SOURCE_SYMBOL
        | SWAPS_SYMBOL
    )
;


selectStatement:
    queryExpression lockingClauseList?
    | queryExpressionParens
    | selectStatementWithInto
;

