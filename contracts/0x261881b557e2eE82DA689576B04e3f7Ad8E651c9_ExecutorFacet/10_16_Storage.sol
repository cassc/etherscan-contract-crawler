pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Verifier.sol";
import "../common/interfaces/IAllowList.sol";
import "./libraries/PriorityQueue.sol";

/// @dev Logically separated part of the storage structure, which is responsible for everything related to proxy upgrades and diamond cuts
/// @param proposedDiamondCutHash The hash of diamond cut that was proposed in the current upgrade
/// @param proposedDiamondCutTimestamp The timestamp when the diamond cut was proposed, zero if there are no active proposals
/// @param lastDiamondFreezeTimestamp The timestamp when the diamond was frozen last time, zero if the diamond was never frozen
/// @param currentProposalId The serial number of proposed diamond cuts, increments when proposing a new diamond cut
/// @param securityCouncilMembers The set of the trusted addresses that can instantly finish upgrade (diamond cut)
/// @param securityCouncilMemberLastApprovedProposalId The mapping of the security council addresses and the last diamond cut that they approved
/// @param securityCouncilEmergencyApprovals The number of received upgrade approvals from the security council
struct DiamondCutStorage {
    bytes32 proposedDiamondCutHash;
    uint256 proposedDiamondCutTimestamp;
    uint256 lastDiamondFreezeTimestamp;
    uint256 currentProposalId;
    mapping(address => bool) securityCouncilMembers;
    mapping(address => uint256) securityCouncilMemberLastApprovedProposalId;
    uint256 securityCouncilEmergencyApprovals;
}

/// @dev The log passed from L2
/// @param l2ShardId The shard identifier, 0 - rollup, 1 - porter. All other values are not used but are reserved for the future
/// @param isService A boolean flag that is part of the log along with `key`, `value`, and `sender` address.
/// This field is required formally but does not have any special meaning.
/// @param txNumberInBlock The L2 transaction number in a block, in which the log was sent
/// @param sender The L2 address which sent the log
/// @param key The 32 bytes of information that was sent in the log
/// @param value The 32 bytes of information that was sent in the log
// Both `key` and `value` are arbitrary 32-bytes selected by the log sender
struct L2Log {
    uint8 l2ShardId;
    bool isService;
    uint16 txNumberInBlock;
    address sender;
    bytes32 key;
    bytes32 value;
}

/// @dev An arbitrary length message passed from L2
/// @notice Under the hood it is `L2Log` sent from the special system L2 contract
/// @param txNumberInBlock The L2 transaction number in a block, in which the message was sent
/// @param sender The address of the L2 account from which the message was passed
/// @param data An arbitrary length message
struct L2Message {
    uint16 txNumberInBlock;
    address sender;
    bytes data;
}

/// @notice Part of the configuration parameters of ZKP circuits
struct VerifierParams {
    bytes32 recursionNodeLevelVkHash;
    bytes32 recursionLeafLevelVkHash;
    bytes32 recursionCircuitsSetVksHash;
}

/// @dev storing all storage variables for zkSync facets
/// NOTE: It is used in a proxy, so it is possible to add new variables to the end
/// NOTE: but NOT to modify already existing variables or change their order
struct AppStorage {
    /// @dev Storage of variables needed for diamond cut facet
    DiamondCutStorage diamondCutStorage;
    /// @notice Address which will exercise governance over the network i.e. change validator set, conduct upgrades
    address governor;
    /// @notice Address that governor proposed as one that will replace it
    address pendingGovernor;
    /// @notice List of permitted validators
    mapping(address => bool) validators;
    // TODO: should be used an external library approach
    /// @dev Verifier contract. Used to verify aggregated proof for blocks
    Verifier verifier;
    /// @notice Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
    uint256 totalBlocksExecuted;
    /// @notice Total number of proved blocks i.e. blocks[totalBlocksProved] points at the latest proved block
    uint256 totalBlocksVerified;
    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint256 totalBlocksCommitted;
    /// @dev Stored hashed StoredBlock for block number
    mapping(uint256 => bytes32) storedBlockHashes;
    /// @dev Stored root hashes of L2 -> L1 logs
    mapping(uint256 => bytes32) l2LogsRootHashes;
    /// @dev Container that stores transactions requested from L1
    PriorityQueue.Queue priorityQueue;
    /// @dev The smart contract that manages the list with permission to call contract functions
    IAllowList allowList;
    /// @notice Part of the configuration parameters of ZKP circuits. Used as an input for the verifier smart contract
    VerifierParams verifierParams;
    /// @notice Bytecode hash of bootloader program.
    /// @dev Used as an input to zkp-circuit.
    bytes32 l2BootloaderBytecodeHash;
    /// @notice Bytecode hash of default account (bytecode for EOA).
    /// @dev Used as an input to zkp-circuit.
    bytes32 l2DefaultAccountBytecodeHash;
    /// @dev Indicates that the porter may be touched on L2 transactions.
    /// @dev Used as an input to zkp-circuit.
    bool zkPorterIsAvailable;
}