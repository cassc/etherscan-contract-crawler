// SPDX-License-Identifier: MIT
// WARNING! This smart contract has not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
// This is an example contract to demonstrate how to integrate an application with the audited production release of AxiomV1 and AxiomV1Query.
pragma solidity 0.8.19;

// Constants and free functions to be inlined into by AxiomV1Core

// ZK circuit constants:

// AxiomV1 caches blockhashes in batches, stored as Merkle roots of binary Merkle trees
uint32 constant BLOCK_BATCH_SIZE = 1024;
uint32 constant BLOCK_BATCH_DEPTH = 10;

// constants for batch import of historical block hashes
// historical uploads a bigger batch of block hashes, stored as Merkle roots of binary Merkle trees
uint32 constant HISTORICAL_BLOCK_BATCH_SIZE = 131072; // 2 ** 17
uint32 constant HISTORICAL_BLOCK_BATCH_DEPTH = 17;
// we will consider the historical Merkle tree of blocks as a Merkle tree of the block batch roots
uint32 constant HISTORICAL_NUM_ROOTS = 128; // HISTORICAL_BATCH_SIZE / BLOCK_BATCH_SIZE

// The first 4 * 3 * 32 bytes of proof calldata are reserved for two BN254 G1 points for a pairing check
// It will then be followed by (7 + BLOCK_BATCH_DEPTH * 2) * 32 bytes of public inputs/outputs
uint32 constant AUX_PEAKS_START_IDX = 608; // PUBLIC_BYTES_START_IDX + 7 * 32

// Historical MMR Ring Buffer constants
uint32 constant MMR_RING_BUFFER_SIZE = 8;

/// @dev proofData stores bytes32 and uint256 values in hi-lo format as two uint128 values because the BN254 scalar field is 254 bits
/// @dev The first 12 * 32 bytes of proofData are reserved for ZK proof verification data
// Extract public instances from proof
// The public instances are laid out in the proof calldata as follows:
// First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
// 384..384 + 32 * 2: prevHash (32 bytes) as two uint128 cast to uint256, because zk proof uses 254 bit field and cannot fit uint256 into a single element
// 384 + 32 * 2..384 + 32 * 4: endHash (32 bytes) as two uint128 cast to uint256
// 384 + 32 * 4..384 + 32 * 5: startBlockNumber (uint32: 4 bytes) and endBlockNumber (uint32: 4 bytes) are concatenated as `startBlockNumber . endBlockNumber` (8 bytes) and then cast to uint256
// 384 + 32 * 5..384 + 32 * 7: root (32 bytes) as two uint128 cast to uint256, this is the highest peak of the MMR if endBlockNumber - startBlockNumber == 1023, otherwise 0
function getBoundaryBlockData(bytes calldata proofData)
    pure
    returns (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root)
{
    prevHash = bytes32(uint256(bytes32(proofData[384:416])) << 128 | uint256(bytes32(proofData[416:448])));
    endHash = bytes32(uint256(bytes32(proofData[448:480])) << 128 | uint256(bytes32(proofData[480:512])));
    startBlockNumber = uint32(bytes4(proofData[536:540]));
    endBlockNumber = uint32(bytes4(proofData[540:544]));
    root = bytes32(uint256(bytes32(proofData[544:576])) << 128 | uint256(bytes32(proofData[576:608])));
}

// We have a Merkle mountain range of max depth BLOCK_BATCH_DEPTH (so length BLOCK_BATCH_DEPTH + 1 total) ordered in **decreasing** order of peak size, so:
// `root` from `getBoundaryBlockData` is the peak for depth BLOCK_BATCH_DEPTH
// `getAuxMmrPeak(proofData, i)` is the peaks for depth BLOCK_BATCH_DEPTH - 1 - i
// 384 + 32 * 7 + 32 * 2 * i .. 384 + 32 * 7 + 32 * 2 * (i + 1): (32 bytes) as two uint128 cast to uint256, same as blockHash
// Note that the decreasing ordering is *different* than the convention in library MerkleMountainRange
function getAuxMmrPeak(bytes calldata proofData, uint256 i) pure returns (bytes32) {
    return bytes32(
        uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64:AUX_PEAKS_START_IDX + i * 64 + 32])) << 128
            | uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64 + 32:AUX_PEAKS_START_IDX + (i + 1) * 64]))
    );
}

interface IAxiomV1Verifier {
    /// @notice A merkle proof to verify a block against the verified blocks cached by Axiom
    /// @dev    `BLOCK_BATCH_DEPTH = 10`
    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[BLOCK_BATCH_DEPTH] merkleProof;
    }

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash. Assumes that blockNumber is within the last 256 most recent blocks.
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) external view returns (bool);

    /// @notice Verify the blockhash of block witness.blockNumber equals witness.claimedBlockHash by checking against Axiom's cache of #historicalRoots.
    /// @dev    For block numbers within the last 256, use #isRecentBlockHashValid instead.
    /// @param  witness The block hash to verify and the Merkle proof to verify it
    ///         witness.blockNumber is the block number to verify
    ///         witness.claimedBlockHash is the claimed blockhash of block witness.blockNumber
    ///         witness.prevHash is the prevHash stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.numFinal is the numFinal stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof is the Merkle inclusion proof of witness.claimedBlockHash to the root stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof[i] is the sibling of the Merkle node at depth 10 - i, for i = 0, ..., 10
    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash by checking against Axiom's cache of historical Merkle mountain ranges in #mmrRingBuffer.
    /// @dev    Use event logs to determine the correct bufferId and get the MMR at that index in the ring buffer.
    /// @param  mmr The Merkle mountain range commited to in #mmrRingBuffer(bufferId), must be correct length
    /// @param  bufferId The index in the ring buffer of #mmrRingBuffer
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    /// @param  merkleProof The Merkle inclusion proof of claimedBlockHash to the corresponding peak in mmr. The correct peak is calculated from mmr.length and blockNumber.
    function mmrVerifyBlockHash(
        bytes32[] calldata mmr,
        uint8 bufferId,
        uint32 blockNumber,
        bytes32 claimedBlockHash,
        bytes32[] calldata merkleProof
    ) external view;
}

// The depth of the Merkle root of queries in:
//   `keccakBlockResponse`, `keccakAccountResponse`, and `keccakStorageResponse`
uint32 constant QUERY_MERKLE_DEPTH = 6;

interface IAxiomV1Query {
    /// @notice States of an on-chain query
    /// @param  Inactive The query has not been made or was refunded.
    /// @param  Active The query has been requested, but not fulfilled.
    /// @param  Fulfilled The query was successfully fulfilled.
    enum AxiomQueryState {
        Inactive,
        Active,
        Fulfilled
    }

    /// @notice Stores metadata about a query 
    /// @param  payment The ETH payment received, in wei. 
    /// @param  state The state of the query.
    /// @param  deadlineBlockNumber The deadline (in block number) after which a refund may be granted.
    /// @param  refundee The address funds should be returned to if the query is not fulfilled.
    struct AxiomQueryMetadata {
        uint256 payment;
        AxiomQueryState state; 
        uint32 deadlineBlockNumber;
        address payable refundee;
    }

    /// @notice Response values read from ZK proof for query.
    /// @param  poseidonBlockResponse Poseidon Merkle root of `poseidon(blockHash . blockNumber . poseidon_tree_root(block_header))`
    /// @param  keccakBlockResponse Keccak Merkle root of `keccak(blockHash . blockNumber)` 
    /// @param  poseidonAccountResponse Poseidon Merkle root of `poseidon(poseidonBlockResponseRow . poseidon(stateRoot . addr . poseidon_tree_root(account_state)))`
    /// @param  keccakAccountResponse Keccak Merkle root of `keccak(blockNumber . addr . keccak(nonce . balance . storageRoot . codeHash))`
    /// @param  poseidonStorageResponse Poseidon Merkle root of `poseidon(poseidonBlockResponseRow . poseidonAccountResponseRow . poseidon(storageRoot . slot . value))`
    /// @param  keccakStorageResponse Keccak Merkle root of `keccak(blockNumber . addr . slot . value)`
    /// @param  historicalMMRKeccak `keccak256(abi.encodePacked(mmr[10:]))`
    /// @param  recentMMRKeccak `keccak256(abi.encodePacked(mmr[:10]))`
    //  Detailed documentation on format here: https://hackmd.io/@axiom/S17K2drf2
    //  ** `poseidonBlockResponseRow = poseidon(blockHash . blockNumber . poseidon_tree_root(block_header))`
    //  ** `poseidonAccountResponseRow = poseidon(stateRoot . addr . poseidon_tree_root(account_state)))`
    //  ** `mmr` is a variable length array of bytes32 containing the Merkle Mountain Range the ZK proof is proving into.
    //     `mmr[idx]` is either `bytes32(0)` or the Merkle root of `1 << idx` block hashes.
    //  ** `mmr` is guaranteed to have length at least `10` and at most `32`.
    struct AxiomMMRQueryResponse {
        bytes32 poseidonBlockResponse;
        bytes32 keccakBlockResponse;
        bytes32 poseidonAccountResponse; 
        bytes32 keccakAccountResponse;
        bytes32 poseidonStorageResponse;
        bytes32 keccakStorageResponse;
        bytes32 historicalMMRKeccak;
        bytes32 recentMMRKeccak;
    }

    /// @notice Stores witness data for checking MMRs
    /// @param  prevHash The `prevHash` as in `IAxiomV1State`.
    /// @param  root The `root` as in `IAxiomV1State`.
    /// @param  numFinal The `numFinal` as in `IAxiomV1State`.  
    /// @param  startBlockNumber The `startBlockNumber` as in `IAxiomV1State`.
    /// @param  recentMMRPeaks Peaks of the MMR committed to in the public input `recentMMRKeccak` of the ZK proof.
    /// @param  mmrComplementOrPeaks If `len(recentMMRPeaks) <= numFinal`, then this is a complementary MMR containing  
    ///         the complement of `recentMMRPeaks` which together with `recentMMRPeaks` forms `root`.  
    ///         If `len(recentMMRPeaks) > numFinal`, then this is the MMR peaks of the `numFinal` blockhashes commited
    ///         to in `root`.
    struct RecentMMRWitness {
        bytes32 prevHash;
        bytes32 root;
        uint32 numFinal;
        uint32 startBlockNumber;        
        bytes32[10] recentMMRPeaks;
        bytes32[10] mmrComplementOrPeaks;
    }

    /// @notice Store a query result into a single block
    /// @param  blockNumber The block number.
    /// @param  blockHash The block hash.
    /// @param  leafIdx The position of this result in the Merkle tree committed to by `keccakBlockResponse`.
    /// @param  proof A Merkle proof into `keccakBlockResponse`.
    struct BlockResponse {
        uint32 blockNumber;
        bytes32 blockHash;

        uint32 leafIdx;
        bytes32[QUERY_MERKLE_DEPTH] proof;
    }

    /// @notice Store a query result into a single block
    /// @param  blockNumber The block number.
    /// @param  addr The address.
    /// @param  nonce The nonce.
    /// @param  balance The balance.
    /// @param  storageRoot The storage root.
    /// @param  codeHash The code hash.
    /// @param  leafIdx The position of this result in the Merkle tree committed to by `keccakAccountResponse`.
    /// @param  proof A Merkle proof into `keccakAccountResponse`.
    //  Note: Fields are zero-padded by prefixing with zero bytes to:
    //    * `nonce`: 8 bytes
    //    * `balance`: 12 bytes
    //    * `storageRoot`: 32 bytes
    //    * `codeHash`: 32 bytes    
    struct AccountResponse {
        uint32 blockNumber;        
        address addr;
        uint64 nonce;
        uint96 balance;
        bytes32 storageRoot;
        bytes32 codeHash;

        uint32 leafIdx;
        bytes32[QUERY_MERKLE_DEPTH] proof;
    }

    /// @notice Store a query result into a single block
    /// @param  blockNumber The block number.
    /// @param  addr The address.
    /// @param  slot The storage slot index. 
    /// @param  value The storage slot value.
    /// @param  leafIdx The position of this result in the Merkle tree committed to by `keccakStorageResponse`.
    /// @param  proof A Merkle proof into `keccakStorageResponse`.
    struct StorageResponse {
        uint32 blockNumber;
        address addr;
        uint256 slot;
        uint256 value;

        uint32 leafIdx;
        bytes32[QUERY_MERKLE_DEPTH] proof;
    }    

    /// @notice Read the set of verified query responses in Keccak form.
    /// @param  hash `verifiedKeccakResults(keccak256(keccakBlockResponse . keccakAccountResponse . keccakStorageResponse)) == true` 
    ///         if and only if each of `keccakBlockResponse`, `keccakAccountResponse`, and `keccakStorageResponse` have been verified
    ///         on-chain by a ZK proof.
    function verifiedKeccakResults(bytes32 hash) external view returns (bool);

    /// @notice Read the set of verified query responses in Poseidon form.
    /// @param  hash `verifiedPoseidonResults(keccak256(poseidonBlockResponse . poseidonAccountResponse . poseidonStorageResponse)) == true` 
    ///         if and only if each of `poseidonBlockResponse`, `poseidonAccountResponse`, and `poseidonStorageResponse` have been
    ///         verified on-chain by a ZK proof.
    function verifiedPoseidonResults(bytes32 hash) external view returns (bool);

    /// @notice Returns the metadata associated to a query
    /// @param  keccakQueryResponse The hash of the query response.
    function queries(bytes32 keccakQueryResponse) external view 
        returns (
            uint256 payment,
            AxiomQueryState state,
            uint32 deadlineBlockNumber,
            address payable refundee
        );

    /// @notice Emitted when the `AxiomV1Core` address is updated.
    /// @param  newAddress The updated address.
    event UpdateAxiomAddress(address newAddress);

    /// @notice Emitted when the batch query verifier address is updated.
    /// @param  newAddress The updated address.
    event UpdateMMRVerifierAddress(address newAddress);

    /// @notice Emitted when a Keccak result is recorded
    /// @param  keccakBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakStorageResponse As documented in `AxiomMMRQueryResponse`.
    event KeccakResultEvent(bytes32 keccakBlockResponse, bytes32 keccakAccountResponse, bytes32 keccakStorageResponse);

    /// @notice Emitted when a Poseidon result is recorded
    /// @param  poseidonBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonStorageResponse As documented in `AxiomMMRQueryResponse`.
    event PoseidonResultEvent(bytes32 poseidonBlockResponse, bytes32 poseidonAccountResponse, bytes32 poseidonStorageResponse);

    /// @notice Emitted when the `minQueryPrice` is updated.
    /// @param  minQueryPrice The new `minQueryPrice`.
    event UpdateMinQueryPrice(uint256 minQueryPrice);

    /// @notice Emitted when the `maxQueryPrice` is updated.
    /// @param  maxQueryPrice The new `maxQueryPrice`.
    event UpdateMaxQueryPrice(uint256 maxQueryPrice);

    /// @notice Emitted when the `queryDeadlineInterval` is updated.
    /// @param  queryDeadlineInterval The new `queryDeadlineInterval`.
    event UpdateQueryDeadlineInterval(uint32 queryDeadlineInterval);

    /// @notice Emitted when a new query with off-chain data availability is requested.
    /// @param  keccakQueryResponse The hash of the claimed query response.
    /// @param  payment The ETH payment offered, in wei.
    /// @param  deadlineBlockNumber The deadline block number after which a refund is possible.
    /// @param  refundee The address of the refundee.
    /// @param  ipfsHash A content-addressed hash on IPFS where the query spec may be found.
    event QueryInitiatedOffchain(bytes32 keccakQueryResponse, uint256 payment, uint32 deadlineBlockNumber, address refundee, bytes32 ipfsHash);

    /// @notice Emitted when a new query with on-chain data availability is requested.
    /// @param  keccakQueryResponse The hash of the claimed query response.
    /// @param  payment The ETH payment offered, in wei.
    /// @param  deadlineBlockNumber The deadline block number after which a refund is possible.
    /// @param  refundee The address of the refundee.
    /// @param  queryHash The hash of the on-chain query.    
    event QueryInitiatedOnchain(bytes32 keccakQueryResponse, uint256 payment, uint32 deadlineBlockNumber, address refundee, bytes32 queryHash);

    /// @notice Emitted when a query is fulfilled.
    /// @param  keccakQueryResponse The hash of the query response.
    /// @param  payment The ETH payment collected, in wei.
    /// @param  prover The address of the prover collecting payment.
    event QueryFulfilled(bytes32 keccakQueryResponse, uint256 payment, address prover);

    /// @notice Emitted when a query is refunded.
    /// @param  keccakQueryResponse The hash of the query response.
    /// @param  payment The ETH payment refunded minus gas, in wei.
    /// @param  refundee The address collecting the refund.    
    event QueryRefunded(bytes32 keccakQueryResponse, uint256 payment, uint32 deadlineBlockNumber, address refundee);

    /// @notice Verify a query result on-chain.
    /// @param  mmrIdx The index of the cached MMR to verify against.
    /// @param  mmrWitness Witness data to reconcile `recentMMR` against `historicalRoots`.
    /// @param  proof The ZK proof data.
    function verifyResultVsMMR(
        uint32 mmrIdx, 
        RecentMMRWitness calldata mmrWitness,                   
        bytes calldata proof
    ) external;                

    /// @notice Request proof for query with on-chain query data availability.
    /// @param  keccakQueryResponse The Keccak-encoded query response.
    /// @param  refundee The address refunds should be sent to.
    /// @param  query The serialized query.
    function sendQuery(bytes32 keccakQueryResponse, address payable refundee, bytes calldata query) external payable;

    /// @notice Request proof for query with off-chain query data availability.
    /// @param  keccakQueryResponse The Keccak-encoded query response.
    /// @param  refundee The address refunds should be sent to.
    /// @param  ipfsHash The IPFS hash the query should optionally be posted to.
    function sendOffchainQuery(bytes32 keccakQueryResponse, address payable refundee, bytes32 ipfsHash) external payable;

    /// @notice Fulfill a query request on-chain.
    /// @param  keccakQueryResponse The hashed query response.
    /// @param  payee The address to send payment to.
    /// @param  mmrIdx The index of the cached MMR to verify against.
    /// @param  mmrWitness Witness data to reconcile `recentMMR` against `historicalRoots`.
    /// @param  proof The ZK proof data.
    function fulfillQueryVsMMR(
        bytes32 keccakQueryResponse, 
        address payable payee, 
        uint32 mmrIdx, 
        RecentMMRWitness calldata mmrWitness,          
        bytes calldata proof
    ) external;

    /// @notice Trigger refund collection for a query after the deadline has expired.
    /// @param keccakQueryResponse THe hashed query response.
    function collectRefund(bytes32 keccakQueryResponse) external;

    /// @notice Checks whether an unpacked query response has already been verified.
    /// @param  keccakBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakStorageResponse As documented in `AxiomMMRQueryResponse`.
    function isKeccakResultValid(bytes32 keccakBlockResponse, bytes32 keccakAccountResponse, bytes32 keccakStorageResponse)
        external
        view
        returns (bool);

    /// @notice Checks whether an unpacked query response has already been verified.
    /// @param  poseidonBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonStorageResponse As documented in `AxiomMMRQueryResponse`.
    function isPoseidonResultValid(bytes32 poseidonBlockResponse, bytes32 poseidonAccountResponse, bytes32 poseidonStorageResponse)
        external
        view
        returns (bool);        

    /// @notice Verify block, account, and storage data against responses which have already been proven.
    /// @param  keccakBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakStorageResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  blockResponses The list of block results.
    /// @param  accountResponses The list of account results.
    /// @param  storageResponses The list of storage results.
    // block_response = keccak(blockHash . blockNumber)
    // account_response = hash(blockNumber . address . hash_tree_root(account_state))
    // storage_response = hash(blockNumber . address . slot . value)
    function areResponsesValid(
        bytes32 keccakBlockResponse,
        bytes32 keccakAccountResponse,
        bytes32 keccakStorageResponse,
        BlockResponse[] calldata blockResponses,
        AccountResponse[] calldata accountResponses,
        StorageResponse[] calldata storageResponses
    ) external view returns (bool);
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract AccountAge is Ownable {
    address public axiomQueryAddress;

    mapping(address => uint32) public birthBlocks;

    event UpdateAxiomQueryAddress(address newAddress);
    event AccountAgeVerified(address account, uint32 birthBlock);

    constructor(address _axiomQueryAddress) {
        axiomQueryAddress = _axiomQueryAddress;
        emit UpdateAxiomQueryAddress(_axiomQueryAddress);
    }

    function updateAxiomQueryAddress(address _axiomQueryAddress) external onlyOwner {
        axiomQueryAddress = _axiomQueryAddress;
        emit UpdateAxiomQueryAddress(_axiomQueryAddress);
    }

    function verifyAge(IAxiomV1Query.AccountResponse[] calldata accountProofs, bytes32[3] calldata keccakResponses)
        external
    {
        require(accountProofs.length == 2, "Too many account proofs");
        address account = accountProofs[0].addr;
        require(account == accountProofs[1].addr, "Accounts are not the same");
        require(accountProofs[0].blockNumber + 1 == accountProofs[1].blockNumber, "Block numbers are not consecutive");
        require(accountProofs[0].nonce == 0, "Prev block nonce is not 0");
        require(accountProofs[1].nonce > 0, "No account transactions in curr block");
        uint256 addrSize;
        assembly {
            addrSize := extcodesize(account)
        }
        require(addrSize == 0, "Account is a contract");

        require(
            IAxiomV1Query(axiomQueryAddress).areResponsesValid(
                keccakResponses[0],
                keccakResponses[1],
                keccakResponses[2],
                new IAxiomV1Query.BlockResponse[](0),
                accountProofs,
                new IAxiomV1Query.StorageResponse[](0)
            ),
            "Proof not valid"
        );

        birthBlocks[account] = accountProofs[0].blockNumber;
        emit AccountAgeVerified(account, accountProofs[0].blockNumber);
    }
}