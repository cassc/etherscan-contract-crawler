// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./core/IAxiomV1Verifier.sol";

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