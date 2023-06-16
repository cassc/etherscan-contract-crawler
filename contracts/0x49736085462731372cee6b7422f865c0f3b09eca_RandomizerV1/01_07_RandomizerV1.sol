// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "./interfaces/IRandomizerV1.sol";
import "./interfaces/IPRTCLCollections721V1.sol";

/**
 * @title RandomizerV1
 * @notice Smart contract only used by Particle's Core ERC-721 contract to set seeds for coordinate pseudo-randomization.
 * Called only once, when the last token for a collection is minted.
 * @dev Uses a list of prime numbers to avoid collisions between tokens within the same collection.
 * @dev Based on Artblock's BasicRandomizerV2 contract: https://github.com/ArtBlocks/artblocks-contracts/blob/main/contracts/BasicRandomizerV2.sol
 *
 * Modifications to the original design:
 * - Removed ownership
 * - Added prime coordinate calculation to avoid collisions between tokens within the same collection
 * - To guarantee no collisions, all possible prime numbers used must be above the maximum number of tokens in a collection. 1 million in this implementation, DO NOT USE COLLECTION SIZES ABOVE 1 MILLION.
 * - Added block difficulty to randomness calculation
 */
contract RandomizerV1 is IRandomizerV1 {
    // Core ERC721 contract
    IPRTCLCollections721V1 public immutable collectionsContract;

    uint24[] private _primes = [1000099,1000117,1000121,1000133,1000151,1000159,1000171,1000183,1000187,1000193,1000199,1000211,1000213,1000231,1000249,1000253,1000273,1000289,1000291,1000303,1000313,1000333,1000357,1000367,1000381,1000393,1000397,1000403,1000409,1000423,1000427,1000429,1000453,1000457,1000507,1000537,1000541,1000547,1000577,1000579,1000589,1000609,1000619,1000621,1000639,1000651,1000667,1000669,1000679,1000691,1000697,1000721,1000723,1000763,1000777,1000793,1000829,1000847,1000849,1000859,1000861,1000889,1000907,1000919,1000921,1000931,1000969,1000973,1000981,1000999,1001003,1001017,1001023,1001027,1001041,1001069,1001081,1001087,1001089,1001093,1001107,1001123,1001153,1001159,1001173,1001177,1001191,1001197,1001219,1001237,1001267,1001279,1001291,1001303,1001311,1001321,1001323,1001327,1001347,1001353,1001369,1001381,1001387,1001389,1001401,1001411,1001431,1001447,1001459,1001467,1001491,1001501,1001527,1001531,1001549,1001551,1001563,1001569,1001587,1001593,1001621,1001629,1001639,1001659,1001669,1001683,1001687,1001713,1001723,1001743,1001783,1001797,1001801,1001807,1001809,1001821,1001831,1001839,1001911,1001933,1001941,1001947,1001953,1001977,1001981,1001983,1001989,1002017,1002049,1002061,1002073,1002077,1002083,1002091,1002101,1002109,1002121,1002143,1002149,1002151,1002173,1002191,1002227,1002241,1002247,1002257,1002259,1002263,1002289,1002299,1002341,1002343,1002347,1002349,1002359,1002361,1002377,1002403,1002427,1002433,1002451,1002457,1002467,1002481,1002487,1002493,1002503,1002511,1002517,1002523,1002527,1002553,1002569,1002577,1002583,1002619,1002623,1002647,1002653,1002679];

    constructor(IPRTCLCollections721V1 _collectionsContract) {
        collectionsContract = _collectionsContract;
    }

    /// @notice Sets random prime seeds for the collection
    /// @dev Only callable by the core ERC721 contract
    function setCollectionSeeds(uint256 _collectionId) external {
        require(msg.sender == address(collectionsContract), "Only collections contract may call");
        uint256 index1 = _getIndex(block.number, _collectionId);
        uint256 index2 = _getIndex(block.number - 1, _collectionId);

        collectionsContract.setCollectionSeeds(_collectionId, [_primes[index1], _primes[index2]]);
    }

    /// @notice Get a random index based on the block number, collection ID, blockhash, timestamp and difficulty.
    function _getIndex(uint256 blockNumber, uint256 _collectionId) private view returns(uint256) {
        uint256 time = block.timestamp;
        // Source of randomness after beacon chain upgrade
        // See https://eips.ethereum.org/EIPS/eip-4399
        uint256 randomness = block.difficulty;
        return uint256(keccak256(
            abi.encodePacked(
                _collectionId,
                blockNumber,
                blockhash(blockNumber - 1),
                time,
                (time % 200) + 1,
                randomness
            )
        )) % _primes.length;
    }
}