/**
 * Copyright Deusty LLC.
**/

#import <Foundation/Foundation.h>

#import "YapDatabase.h"
#import "YapDatabaseConnection.h"
#import "YapDatabaseTransaction.h"

#import "YapDatabaseCloudCoreOptions.h"
#import "YapDatabaseCloudCore.h"
#import "YapDatabaseCloudCoreConnection.h"
#import "YapDatabaseCloudCoreTransaction.h"

#import "YapDatabaseCloudCoreOperationPrivate.h"
#import "YapDatabaseCloudCorePipelinePrivate.h"
#import "YapDatabaseCloudCoreGraphPrivate.h"

#import "YapCache.h"
#import "YapManyToManyCache.h"

#ifdef SQLITE_HAS_CODEC
  #import <SQLCipher/sqlite3.h>
#else
  #import "sqlite3.h"
#endif

/**
 * This version number is stored in the yap2 table.
 * If there is a major re-write to this class, then the version number will be incremented,
 * and the class can automatically rebuild the tables as needed.
**/
#define YAPDATABASE_CLOUDCORE_CLASS_VERSION 3

static NSString * const YDBCloudCore_DiryMappingMetadata_NeedsRemove = @"NeedsRemove";
static NSString * const YDBCloudCore_DiryMappingMetadata_NeedsInsert = @"NeedsInsert";

static NSString *const changeset_key_modifiedMappings = @"modifiedMappings"; // YapManyToManyCache: rowid <-> URI
static NSString *const changeset_key_modifiedTags     = @"modifiedTags";     // Dict : CK -> (changeTag || NSNull)
static NSString *const changeset_key_reset            = @"reset";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface YapDatabaseCloudCore () {
@public
	
	YDBCloudCoreOperationSerializer operationSerializer;
	YDBCloudCoreOperationDeserializer operationDeserializer;
	
	NSString *versionTag;
	YapDatabaseCloudCoreOptions *options;
}

- (NSString *)pipelineV2TableName; // For migration from OLD verion of table
- (NSString *)pipelineV3TableName; // Latest version of table

- (NSString *)queueV1TableName;  // For migration from OLD verion of table
- (NSString *)queueV2TableName;  // Latest version of table

- (NSString *)pipelineTableName; // Always returns latest version
- (NSString *)queueTableName;    // Always returns latest version
- (NSString *)tagTableName;
- (NSString *)mappingTableName;

- (void)commitAddedGraphs:(NSDictionary<NSString *, YapDatabaseCloudCoreGraph *> *)addedGraphs
       insertedOperations:(NSDictionary<NSString *, NSDictionary *> *)insertedOperations
       modifiedOperations:(NSDictionary<NSUUID *, YapDatabaseCloudCoreOperation *> *)modifiedOperations;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface YapDatabaseCloudCoreConnection () {
@protected
	
	id sharedKeySetForInternalChangeset;
	
@public
	
	__strong YapDatabaseCloudCore *parent;
	__unsafe_unretained YapDatabaseConnection *databaseConnection;
	
	NSMutableDictionary<NSString *, NSMutableArray<YapDatabaseCloudCoreOperation *> *> *operations_added;
	NSMutableDictionary<NSString *, NSMutableDictionary *> *operations_inserted;
	NSMutableDictionary<NSUUID *, YapDatabaseCloudCoreOperation *> *operations_modified;
	
	// operations_added    : pipelineName  -> array of added operations (new ops, new graph)
	// operations_inserted : pipelineName  -> dictionary<graphIdx, @[ inserted ops ]> (new ops, previous graph)
	// operations_modified : operationUUID -> modified operation (replacement ops, previous graph)
	
	NSMutableDictionary<NSString *, YapDatabaseCloudCoreGraph *> *graphs_added;
	
	YapManyToManyCache *pendingAttachRequests; // unlimited cache size
	
	YapManyToManyCache *cleanMappingCache;
	YapManyToManyCache *dirtyMappingInfo;  // unlimited cache size
	
	YapCache<YapCollectionKey*, id> *tagCache;
	NSMutableDictionary<YapCollectionKey*, id> *dirtyTags;
	
	BOOL reset;
}

- (id)initWithParent:(YapDatabaseCloudCore *)inParent databaseConnection:(YapDatabaseConnection *)inDbC;

- (void)prepareForReadWriteTransaction;

- (sqlite3_stmt *)pipelineTable_insertStatement;
- (sqlite3_stmt *)pipelineTable_updateStatement;
- (sqlite3_stmt *)pipelineTable_removeStatement;
- (sqlite3_stmt *)pipelineTable_removeAllStatement;

- (sqlite3_stmt *)queueTable_insertStatement;
- (sqlite3_stmt *)queueTable_modifyStatement;
- (sqlite3_stmt *)queueTable_removeStatement;
- (sqlite3_stmt *)queueTable_removeAllStatement;

- (sqlite3_stmt *)tagTable_setStatement;
- (sqlite3_stmt *)tagTable_fetchStatement;
- (sqlite3_stmt *)tagTable_removeForBothStatement;
- (sqlite3_stmt *)tagTable_removeForCloudURIStatement;
- (sqlite3_stmt *)tagTable_removeAllStatement;

- (sqlite3_stmt *)mappingTable_insertStatement;
- (sqlite3_stmt *)mappingTable_fetchStatement;
- (sqlite3_stmt *)mappingTable_fetchForRowidStatement;
- (sqlite3_stmt *)mappingTable_fetchForCloudURIStatement;
- (sqlite3_stmt *)mappingTable_removeStatement;
- (sqlite3_stmt *)mappingTable_removeAllStatement;

- (void)postCommitCleanup;
- (void)postRollbackCleanup;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef NS_OPTIONS(uint8_t, YDBCloudCore_EnumOps) {
	YDBCloudCore_EnumOps_Existing = 1 << 0,
	YDBCloudCore_EnumOps_Inserted = 1 << 1,
	YDBCloudCore_EnumOps_Added    = 1 << 2,
	YDBCloudCore_EnumOps_All      = YDBCloudCore_EnumOps_Existing |
	                                YDBCloudCore_EnumOps_Inserted |
	                                YDBCloudCore_EnumOps_Added,
};

@interface YapDatabaseCloudCoreTransaction () {
@protected

	__unsafe_unretained YapDatabaseCloudCoreConnection *parentConnection;
	__unsafe_unretained YapDatabaseReadTransaction *databaseTransaction;
}

- (id)initWithParentConnection:(YapDatabaseCloudCoreConnection *)parentConnection
           databaseTransaction:(YapDatabaseReadTransaction *)databaseTransaction;

/**
 * Subclass hooks
**/

// Allows subclasses to perform post-processing on operations before they are written to disk.
// Examples of tasks a subclass may want to perform:
//
// - sanitization of various property values
// - automatically merging duplicate operations within same commit
// - automatically adding dependencies for operations in earlier commits (if using FlatGraph optimization)
//
- (NSArray *)processOperations:(NSArray *)operations
						  inPipeline:(YapDatabaseCloudCorePipeline *)pipeline
						withGraphIdx:(NSUInteger)operationsGraphIdx;

// Subclasses may override these methods to perform custom tasks as needed.
- (void)didCompleteOperation:(YapDatabaseCloudCoreOperation *)operation;
- (void)didSkipOperation:(YapDatabaseCloudCoreOperation *)operation;

/**
 * All of the public methods that return an operation (directly, or via enumeration block),
 * always return a copy of the internally held operation.
 * 
 * Internal methods can avoid the copy overhead by using the underscore versions below.
**/

- (YapDatabaseCloudCoreOperation *)_operationWithUUID:(NSUUID *)uuid;
- (YapDatabaseCloudCoreOperation *)_operationWithUUID:(NSUUID *)uuid inPipeline:(NSString *)pipelineName;

- (void)_enumerateOperationsUsingBlock:(void (^)(YapDatabaseCloudCorePipeline *pipeline,
                                                 YapDatabaseCloudCoreOperation *operation,
                                                 NSUInteger graphIdx, BOOL *stop))enumBlock;

- (void)_enumerateOperationsInPipeline:(NSString *)pipelineName
                            usingBlock:(void (^)(YapDatabaseCloudCoreOperation *operation,
                                                 NSUInteger graphIdx, BOOL *stop))enumBlock;

- (void)_enumerateOperations:(YDBCloudCore_EnumOps)flags
                  usingBlock:(void (^)(YapDatabaseCloudCorePipeline *pipeline,
                                       YapDatabaseCloudCoreOperation *operation,
                                       NSUInteger graphIdx, BOOL *stop))enumBlock;

- (void)_enumerateOperations:(YDBCloudCore_EnumOps)flags
                  inPipeline:(YapDatabaseCloudCorePipeline *)pipeline
                  usingBlock:(void (^)(YapDatabaseCloudCoreOperation *operation,
                                       NSUInteger graphIdx, BOOL *stop))enumBlock;

- (void)_enumerateAndModifyOperations:(YDBCloudCore_EnumOps)flags
                           usingBlock:(YapDatabaseCloudCoreOperation *
                                      (^)(YapDatabaseCloudCorePipeline *pipeline,
                                          YapDatabaseCloudCoreOperation *operation,
                                          NSUInteger graphIdx, BOOL *stop))enumBlock;

- (void)_enumerateAndModifyOperations:(YDBCloudCore_EnumOps)flags
                           inPipeline:(YapDatabaseCloudCorePipeline *)pipeline
                           usingBlock:(YapDatabaseCloudCoreOperation *
                                      (^)(YapDatabaseCloudCoreOperation *operation,
                                          NSUInteger graphIdx, BOOL *stop))enumBlock;

/**
 * Throw this if an attempt is made to invoke a read-write action within a read-only transaction.
**/
- (NSException *)requiresReadWriteTransactionException:(NSString *)methodName;

@end
