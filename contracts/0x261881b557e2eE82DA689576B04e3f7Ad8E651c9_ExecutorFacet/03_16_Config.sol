pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



bytes32 constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

/// @dev Bytes in raw L2 log
/// @dev Equal to the bytes size of the tuple - (uint8 ShardId, bool isService, uint16 txNumberInBlock, address sender, bytes32 key, bytes32 value)
uint256 constant L2_TO_L1_LOG_SERIALIZE_SIZE = 88;

/// @dev Length of the bytes array with L2->L1 logs
uint256 constant L2_TO_L1_LOGS_COMMITMENT_BYTES = 4 + L2_TO_L1_LOG_SERIALIZE_SIZE * 512;

/// @dev L2 -> L1 logs Merkle tree height
uint256 constant L2_TO_L1_LOG_MERKLE_TREE_HEIGHT = 9;

/// @dev The value of default leaf hash for L2 -> L1 logs Merkle tree
/// @dev An incomplete fixed-size tree is filled with this value to be a full binary tree
/// @dev Actually equal to the `keccak256(new bytes(L2_LOG_BYTES))`
bytes32 constant L2_L1_LOGS_TREE_DEFAULT_LEAF_HASH = 0x72abee45b59e344af8a6e520241c4744aff26ed411f4c4b00f8af09adada43ba;

/// @dev Length of the bytes array with initial storage changes
uint256 constant INITIAL_STORAGE_CHANGES_COMMITMENT_BYTES = 4 + 64 * 4896;

/// @dev Length of the bytes array with repeated storage changes
uint256 constant REPEATED_STORAGE_CHANGES_COMMITMENT_BYTES = 4 + 40 * 7787;

// TODO: change constant to the real root hash of empty Merkle tree (SMA-184)
bytes32 constant DEFAULT_L2_LOGS_TREE_ROOT_HASH = bytes32(0);

/// @dev The address of the special smart contract that can send arbitrary length message as an L2 log
address constant L2_TO_L1_MESSENGER = address(0x8008);

/// @dev The address of the bootloader start program
address constant L2_BOOTLOADER_ADDRESS = address(0x8001);

/// @dev The address of the known code storage system contract
address constant L2_KNOWN_CODE_STORAGE_ADDRESS = address(0x8004);

/// @dev The address of the context system contract
address constant L2_SYSTEM_CONTEXT_ADDRESS = address(0x800b);

/// @dev Denotes the first byte of the zkSync transaction that came from L1.
uint256 constant PRIORITY_OPERATION_L2_TX_TYPE = 255;

/// @dev Expected average period of block creation
uint256 constant BLOCK_PERIOD = 13 seconds;

/// @dev Expiration delta for priority request to be satisfied (in seconds)
/// @dev otherwise incorrect block with priority op could not be reverted.
uint256 constant PRIORITY_EXPIRATION_PERIOD = 3 days;

/// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
uint256 constant PRIORITY_EXPIRATION = PRIORITY_EXPIRATION_PERIOD/BLOCK_PERIOD;

/// @dev Notice period before activation preparation status of upgrade mode (in seconds)
/// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
uint256 constant UPGRADE_NOTICE_PERIOD = 0;

/// @dev Timestamp - seconds since unix epoch
uint256 constant COMMIT_TIMESTAMP_NOT_OLDER = 365 days;

/// @dev Maximum available error between real commit block timestamp and analog used in the verifier (in seconds)
/// @dev Must be used cause miner's `block.timestamp` value can differ on some small value (as we know - 15 seconds)
uint256 constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 365 days;

/// @dev Bit mask to apply for verifier public input before verifying.
uint256 constant INPUT_MASK = 452312848583266388373324160190187140051835877600158453279131187530910662655;

/// @dev The maximum number of ergs that a user can request for L1 -> L2 transactions
uint256 constant PRIORITY_TX_MAX_ERGS_LIMIT = 2097152;

/// @dev Number of security council members that should approve an emergency upgrade
uint256 constant SECURITY_COUNCIL_APPROVALS_FOR_EMERGENCY_UPGRADE = 1;