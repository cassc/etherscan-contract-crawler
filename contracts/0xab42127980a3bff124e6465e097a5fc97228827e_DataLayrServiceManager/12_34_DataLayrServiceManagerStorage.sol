// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@eigenlayer/contracts/interfaces/IEigenLayrDelegation.sol";
import "@eigenlayer/contracts/interfaces/IServiceManager.sol";
import "@eigenlayer/contracts/interfaces/IInvestmentManager.sol";

import "../interfaces/IDataLayrServiceManager.sol";

import "./DataLayrChallenge.sol";
import "./DataLayrBombVerifier.sol";

/**
 * @title Storage variables for the `DataLayrServiceManager` contract.
 * @author Layr Labs, Inc.
 * @notice This storage contract is separate from the logic to simplify the upgrade process.
 */
abstract contract DataLayrServiceManagerStorage is IDataLayrServiceManager {
    // CONSTANTS
    uint256 public constant BIP_MULTIPLIER = 10000;

    //TODO: mechanism to change any of these values?
    /// @notice Unit of measure (in time) for the duration of DataStores
    uint256 public constant DURATION_SCALE = 1 hours;
    /// @notice The maximum number of DataStores of a single duration that can be stored in a single block
    uint256 public constant NUM_DS_PER_BLOCK_PER_DURATION = 20;
    /// @notice The shortest allowed duration of a DataStore, measured in `DURATION_SCALE`
    uint8 public constant MIN_DATASTORE_DURATION = 1;
    /// @notice The longest allowed duration of a DataStore, measured in `DURATION_SCALE`
    uint8 public constant MAX_DATASTORE_DURATION = 7;

    /// @notice Minimum DataStore size, in bytes.
    uint32 internal constant MIN_STORE_SIZE = 32;
    /// @notice Maximum DataStore size, in bytes.
    uint32 internal constant MAX_STORE_SIZE = 4e9;
    /**
     * @notice The maximum amount of blocks in the past that the service will consider stake amounts to still be 'valid'.
     * @dev To clarify edge cases, the middleware can look `BLOCK_STALE_MEASURE` blocks into the past, i.e. it may trust stakes from the interval
     * [block.number - BLOCK_STALE_MEASURE, block.number] (specifically, *inclusive* of the block that is `BLOCK_STALE_MEASURE` before the current one)
     */
    uint32 public constant BLOCK_STALE_MEASURE = 150;

    /// @notice service fee that will be paid out by the disperser to the DataLayr nodes for storing data, per byte stored per unit time (second).
    uint256 public feePerBytePerTime;

    /**
     * @notice this is the maximum amount of time that can pass between an intitiation of a DataStore and its confirmation.
     *         a max is set to limit greiving cause to nodes
     */
    uint32 public constant confirmDataStoreTimeout = 30 minutes;

    // TODO: set these values correctly
    /// @notice number of leaves in the root tree
    uint48 public constant numPowersOfTau = 0;
    /// @notice number of layers in the root tree
    uint48 public constant log2NumPowersOfTau = 0;

    //TODO: store these upon construction
    // Commitment(0), Commitment(x - w), Commitment((x-w)(x-w^2)), ...
    /**
     * @notice For a given l, zeroPolynomialCommitmentMerkleRoots[l] represents the root of merkle tree

                                    zeroPolynomialCommitmentMerkleRoots[l]
                                                        :
                                                        :
                         ____________ ....                             .... ____________
                        |                                                               |
                        |                                                               |
              _____h(h_1||h_2)______                                        ____h(h_{k-1}||h_{k}__________
             |                      |                                      |                              |
             |                      |                                      |                              |
            h_1                    h_2                                 h_{k-1}                         h_{k}
             |                      |                                      |                              |
             |                      |                                      |                              |
     hash(x^l - w^l)       hash(x^l - (w^2)^l)                   hash(x^l - (w^{k-1})^l)        hash(x^l - (w^k)^l)

     This tree is computed off-chain and only the Merkle roots are stored on-chain.
     */
    // CRITIC: does that mean there are only 32 possible 32 possible merkle trees?
    bytes32[32] public zeroPolynomialCommitmentMerkleRoots;

    /**
     * @notice mapping between the dataStoreId for a particular assertion of data into
     * DataLayr and a compressed information on the signatures of the DataLayr
     * nodes who signed up to be the part of the quorum.
     */
    mapping(uint32 => bytes32) public dataStoreIdToSignatureHash;
    /**
     * @notice Mapping from duration to timestamp to all of the ids of datastores that were initialized during that timestamp.
     * The third nested mapping just keeps track of a fixed number of datastores of a certain duration that can be in that block
     */
    mapping(uint8 => mapping(uint256 => bytes32[NUM_DS_PER_BLOCK_PER_DURATION])) public
        dataStoreHashesForDurationAtTimestamp;
}