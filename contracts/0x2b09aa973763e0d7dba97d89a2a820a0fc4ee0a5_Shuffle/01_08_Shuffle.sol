// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IShuffle } from "./interfaces/IShuffle.sol";
import { Ownable } from "solady/auth/Ownable.sol";
import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IShards {
    function burn(address account, uint256 id, uint256 amount) external;
}

contract Shuffle is IShuffle, Ownable, VRFConsumerBaseV2 {
    using EnumerableSet for EnumerableSet.UintSet;
    using SSTORE2 for address;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       BIT OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Bit mask used to parse out the pool value.
    uint256 private constant _BITMASK_POOL = (1 << 4) - 1;

    // Bit mask used to parse out the token ID value.
    uint256 private constant _BITMASK_TOKEN_ID = (1 << 16) - 1;

    // Bit mask used to parse out the address value.
    uint256 private constant _BITMASK_USER = (1 << 160) - 1;

    // Bit mask used to parse out each weight value.
    uint256 private constant _BITMASK_WEIGHT = (1 << 14) - 1;

    // Bit mask used to zeroise the non-weight related upper bits.
    uint256 private constant _BITMASK_WEIGHTS = (1 << 70) - 1;
    
    // Bit position of `fulfilled` boolean value.
    uint256 private constant _BITPOS_FULFILLED = 255;

    // Bit position of `exists` boolean value.
    uint256 private constant _BITPOS_EXISTS = 254;

    // Bit position of `TokenPools` enum value.
    uint256 private constant _BITPOS_POOL = 246;

    // Bit position of `tokenId` value.
    uint256 private constant _BITPOS_TOKEN_ID = 230;

    // Bit position of `user` address.
    uint256 private constant _BITPOS_USER = 70;
    
    // Bit position of the first weight.
    uint256 private constant _BITPOS_WEIGHT = 14;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      RANK THRESHOLDS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Ranks between 7777 and 3889 are categorised as common.
    uint256 private constant _THRESHOLD_COMMON = 3889;

    // Ranks between 3888 and 2333 are categorised as uncommon.
    uint256 private constant _THRESHOLD_UNCOMMON = 2333;

    // Ranks between 2332 and 1167 are categorised as rare.
    uint256 private constant _THRESHOLD_RARE = 1167;

    // Ranks between 1166 and 312 are categorised as epic.
    uint256 private constant _THRESHOLD_EPIC = 312;

    // NOTE: Tokens that exceed rank 312 are considered as grail tokens.

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER CONSTANTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 private constant _EXPECTED_WEIGHT = 10000;

    uint256 private constant _EXPECTED_SIZE = 15554;

    uint256 private constant _SHARD_ID = 0;

    /**
     * `requestData` bit layout.
     * [255..255] fulfilled: Boolean value indicating whether the request has been successfully fulfilled.
     * [254..254] exists: Boolean value indicating whether a request exists.
     * [246..253] pool: Respective pool that `id` will be placed into upon fulfillment.
     * [230..245] tokenId: Isekai Meta token identifier associated with the request.
     * [70...229] user: Address of the caller that invoked the request.
     * [0.....69] weights: Packed weightings associated with each token pool, 14 bits per weight.
     */
    mapping(uint256 requestId => uint256 requestData) private _requests;
    
    // Mapping of pool type to the token IDs that reside within it.
    mapping(TokenPools pool => EnumerableSet.UintSet tokenIds) private _pools;

    // Mapping of pool type to a packed `uint256[5]` weights array.
    mapping(TokenPools pool => uint256 weights) private _weights;

    // Interface of Isekai Meta contract.
    IERC721A public immutable ISEKAI = IERC721A(0x684E4ED51D350b4d76A3a07864dF572D24e6dC4c);
    
    // Interface of Isekai Shards contract.
    IShards public immutable SHARDS = IShards(0xb842b4605F7D3340329122faeA90954CbD15a849);
    
    // Interface for Chainlink VRFCoordinatorV2.
    VRFCoordinatorV2Interface public immutable COORDINATOR;

    // There is no intention to support gwei key hashes above 200 so this variable
    // has been defined as immutable.
    bytes32 public immutable KEY_HASH;

    // Address of the SSTORE2'd ranking data.
    address public immutable rankings;

    // Tracks the current state of the contract.
    ShuffleState public shuffleState;

    // Chainlink stuff.
    uint64 public subscriptionId;
    uint32 public callbackGasLimit = 500_000;
    uint16 public requestConfirmations = 3;

    // Tracks the current number of pending requests. This value been casted to a uint16
    // to prevent a zero to non-zero SSTORE by packing it into the storage slot with the
    // values defined above.
    uint16 public pendingRequests = 0;

    /**
     * Modifier that checks if `shuffleState` matches `desiredState`.
     */
    modifier checkState(ShuffleState desiredState) {
        _checkState(desiredState);
        _;
    }
    
    constructor(
        address coordinator,
        bytes32 keyHash,
        uint64 subId,
        bytes memory data,
        uint256[5][5] memory weightings
    ) VRFConsumerBaseV2(coordinator) {
        _initializeOwner(msg.sender);

        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        KEY_HASH = keyHash;
        subscriptionId = subId;

        // Expected bytes length of constructor argument `data`. Since each ranking
        // is consolidated into 2 bytes of information and there is 7,777 tokens
        // in the Isekai Meta collection, 2 * 7777 (15554) is the desired length.
        if (data.length != _EXPECTED_SIZE) revert InvalidDataSize();
        rankings = SSTORE2.write(data);

        _setPoolWeights(weightings);
    }

    /**
     * @notice Function used to shuffle an Isekai Meta token.
     * @param tokenId Isekai Meta token Identifier.
     */
    function shuffle(uint256 tokenId) external checkState(ShuffleState.ACTIVE) {
        // Ensure that the request can be fulfilled, this line updates `pendingRequests`
        // then checks its value against the return value of `_minPoolSize()`.
        if (++pendingRequests > _minPoolSize()) revert InvalidPoolSize();

        SHARDS.burn(msg.sender, _SHARD_ID, 1);
        ISEKAI.transferFrom(msg.sender, address(this), tokenId);

        TokenPools pool = _poolFromId(tokenId);
        uint256 weightings = _weights[pool];

        uint256 requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );

        _requests[requestId] = _packData(pool, tokenId, msg.sender, weightings);
    }

    /**
     * @notice Function used to add reward tokens to the shuffler.
     * @param tokenIds Array of Isekai Meta token identifiers.
     */
    function addRewardTokens(uint256[] calldata tokenIds)
        external
        onlyOwner
        checkState(ShuffleState.INACTIVE)
    {
        if (tokenIds.length == 0) revert ZeroLengthArray();

        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            ISEKAI.transferFrom(msg.sender, address(this), tokenId);

            if (!_pools[_poolFromId(tokenId)].add(tokenId)) revert AddFailed();

            unchecked { ++i; }
        }
    }

    /**
     * @notice Function used to remove reward tokens from the shuffler.
     * @param tokenIds Array of Isekai Meta token identifiers.
     */
    function removeRewardTokens(uint256[] calldata tokenIds)
        external
        onlyOwner
        checkState(ShuffleState.INACTIVE)
    {
        if (tokenIds.length == 0) revert ZeroLengthArray();

        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (!_pools[_poolFromId(tokenId)].remove(tokenId)) revert RemoveFailed();

            ISEKAI.transferFrom(address(this), msg.sender, tokenId);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Function used to withdraw tokens from the contract. This function
     * is here to ensure tokens NEVER become stuck due to unforseen circumstances.
     * @param tokenIds Array of Isekai Meta token identifiers.
     * @dev If this function is ever called, the contract itself will require
     * redeployment. Use with EXTREME caution.
     */
    function emergencyWithdraw(uint256[] calldata tokenIds) external onlyOwner {
        if (tokenIds.length == 0) revert ZeroLengthArray();
        for (uint256 i = 0; i < tokenIds.length; ) {
            ISEKAI.transferFrom(address(this), msg.sender, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Function used to set a new `shuffleState` value.
     * @param newShuffleState Newly desired `shuffleState` value.
     */
    function setShuffleState(ShuffleState newShuffleState) external onlyOwner {
        shuffleState = newShuffleState;
    }

    /**
     * @notice Function used to view all tokens in `pool`.
     * @param pool Desired token pool to check.
     * @return Returns an array of all token IDs within `pool`.
     */
    function getTokensInPool(TokenPools pool) external view returns (uint256[] memory) {
        return _pools[pool].values();
    }

    /**
     * @notice Function used to view all tokens in every pool.
     * @return tokenIds A multi-dimensional array that contains all token IDs within each token pool.
     */
    function getTokensInAllPools() external view returns (uint256[][] memory tokenIds) {
        uint256 maxPools = uint256(type(TokenPools).max);
        tokenIds = new uint256[][](maxPools + 1);

        for (uint256 i = 0; i <= maxPools; i++) {
            tokenIds[i] = _pools[TokenPools(i)].values();
        }

        return tokenIds;
    }

    /**
     * @notice Function used to view the number of tokens in `pool`.
     * @param pool Desired token pool to check.
     */
    function getAmountOfTokensInPool(TokenPools pool) external view returns (uint256) {
        return _pools[pool].length();
    }

    /**
     * @notice Function used to check if `tokenId` is in `pool`.
     * @param pool Desired token pool to check.
     * @param tokenId Isekai Meta token identifier.
     * @return Returns `true` if `tokenId` exists within `pool`, `false` otherwise.
     */
    function isTokenInPool(TokenPools pool, uint256 tokenId) external view returns (bool) {
        return _pools[pool].contains(tokenId);
    }

    /**
     * @notice Function used to check the weights associated with `pool`.
     * @param pool Desired token pool to check.
     * @return Returns the weights of each token pool for `pool`.
     */
    function weights(TokenPools pool) external view returns (uint256[5] memory) {
        return _unpackWeights(_weights[pool]);
    }

    /**
     * @notice Function used to view the token pool associated with `tokenId`.
     * @param tokenId Isekai Meta token identifier.
     * @return Returns the token pool associated with `tokenId`.
     */
    function poolFromId(uint256 tokenId) external view returns (TokenPools) {
        return _poolFromId(tokenId);
    }

    /**
     * @notice Function used to view the rank of a given `tokenId`.
     * @param tokenId Isekai Meta token identifier.
     * @return Returns the rank associated with the provided `tokenId`.
     */
    function getRank(uint256 tokenId) external view returns (uint256) {
        return _getRank(tokenId);
    }

    /**
     * @notice Function used to view the request data for a given `requestId` value.
     * @param requestId A Chainlink request identifier.
     * @return Returns Human readable request data derived from `PackedRequest.data[requestId]`.
     */
    function requests(uint256 requestId) external view returns (Request memory) {
        uint256 data = _requests[requestId];
        return Request({
            fulfilled: data >> _BITPOS_FULFILLED & 1 == 1,
            exists: data >> _BITPOS_EXISTS & 1 == 1,
            pool: TokenPools(data >> _BITPOS_POOL & _BITMASK_POOL),
            tokenId: data >> _BITPOS_TOKEN_ID & _BITMASK_TOKEN_ID,
            user: address(uint160(data >> _BITPOS_USER & _BITMASK_USER)),
            weights: _unpackWeights(data)
        });
    }

    /**
     * @notice Function used to handle random number fulfillment.
     * @dev It is critical that this function NEVER reverts.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Access the packed data associated with `requestId`.
        uint256 data = _requests[requestId];
        
        // Confirm that the randomness request exists.
        if (data >> _BITPOS_EXISTS & 1 != 1) revert RequestNotFound();

        // Acknowledge the request is being fulfilled and update the respective value.
        _requests[requestId] |= 1 << _BITPOS_FULFILLED;

        // Update pending requests.
        --pendingRequests;

        // Assign random number from `randomWords`.
        uint256 randomNumber = randomWords[0];

        // Run weighted random number algorithm to determine which pool a token will be selected from. The
        // second parameter zeroises the non-weight related bits of `data` to ensure cleanliness.
        TokenPools chosenPool = _chosePool(randomNumber, data & _BITMASK_WEIGHTS);

        // Select a token from the chosen pool, the operation defined within `.at()` mods `randomNumber`
        // by the length of `_pools[chosenPool]` to derive a pseudorandom index between 0 and `length - 1`.
        uint256 tokenOut = _pools[chosenPool].at(randomNumber % _pools[chosenPool].length());

        // Remove the token ID from the pool.
        _pools[chosenPool].remove(tokenOut);

        // Assign original token value.
        uint256 tokenIn = data >> _BITPOS_TOKEN_ID & _BITMASK_TOKEN_ID;

        // Update the pool with the original Isekai that was provided in the initial invocation of `shuffle()`.
        _pools[TokenPools(data >> _BITPOS_POOL & _BITMASK_POOL)].add(tokenIn);

        // Assign receiver.
        address receiver = address(uint160(data >> _BITPOS_USER & _BITMASK_USER));

        // Transfer the chosen Isekai to the owner.
        ISEKAI.transferFrom(address(this), receiver, tokenOut);
        
        // Event emission.
        emit Shuffled(receiver, tokenIn, tokenOut);
    }

    /** 
     * Helper function used to set the weights of each pool. This function is only
     * called within the constructor and pool weightings cannot be modified once set.
     */
    function _setPoolWeights(uint256[5][5] memory weightings) internal {
        for (uint256 i = 0; i < weightings.length; i++) {
            if (_sumWeights(weightings[i]) != _EXPECTED_WEIGHT) revert WeightMismatch();   
            _weights[TokenPools(i)] = _packWeights(weightings[i]);
        }
    }

    /**
     * Helper function that implements a weighted random number algorithim to derive
     * a chosen token pool from the seeded random number and the packed weights.
     */
    function _chosePool(
        uint256 randomNumber,
        uint256 packedWeights
    ) internal pure returns (TokenPools pool) {
        assembly ("memory-safe") {
            // Derive a value within the range of 1 - 10,000.
            let roll := add(mod(randomNumber, _EXPECTED_WEIGHT), 1)

            // Define iterator value.
            let i := 0
            for { let cumulativeWeight := 0 } 1 {} {
                // Assign the current value of `weights[i]`.
                let poolWeight := and(shr(mul(_BITPOS_WEIGHT, i), packedWeights), _BITMASK_WEIGHT)
                
                // Update our `cumulativeWeight` by adding the previous value with `poolWeight`.
                cumulativeWeight := add(cumulativeWeight, poolWeight)

                // If the condition is satifised, break.
                if iszero(gt(roll, cumulativeWeight)) { break }

                // Update iterator value.
                i := add(i, 1)
            }

            // Set the associated `pool` value.
            pool := i
        }
    }

    /**
     * Helper function used to efficiently calculate the sum of the `weightings` array. Since
     * `weightings` is bounded to 5 indices, we can safely unroll the operations.
     */
    function _sumWeights(uint256[5] memory weightings) internal pure returns (uint256 sum) {
        assembly ("memory-safe") {
            sum := mload(weightings)
            sum := add(sum, mload(add(weightings, 0x20)))
            sum := add(sum, mload(add(weightings, 0x40)))
            sum := add(sum, mload(add(weightings, 0x60)))
            sum := add(sum, mload(add(weightings, 0x80)))
        }
    }

    /**
     * Helper function used to efficiently pack the `weightings` array into 70 bits. Since
     * the sum of `weightings` is bounded 10,000, each weight fits snugly into 14 bits.
     */
    function _packWeights(uint256[5] memory weightings) internal pure returns (uint256 packed) {
        assembly ("memory-safe") {
            packed := mload(weightings)
            packed := or(packed, shl(_BITPOS_WEIGHT, mload(add(weightings, 0x20))))
            packed := or(packed, shl(mul(_BITPOS_WEIGHT, 2), mload(add(weightings, 0x40))))
            packed := or(packed, shl(mul(_BITPOS_WEIGHT, 3), mload(add(weightings, 0x60))))
            packed := or(packed, shl(mul(_BITPOS_WEIGHT, 4), mload(add(weightings, 0x80))))
        }
    }

    /**
     * Helper function used to efficiently unpack the `weights_` array from `packedWeights`.
     */
    function _unpackWeights(uint256 packedWeights) internal pure returns (uint256[5] memory weights_) {
        assembly ("memory-safe") {
            mstore(weights_, and(packedWeights, _BITMASK_WEIGHT))
            mstore(add(weights_, 0x20), and(shr(_BITPOS_WEIGHT, packedWeights), _BITMASK_WEIGHT))
            mstore(add(weights_, 0x40), and(shr(mul(_BITPOS_WEIGHT, 2), packedWeights), _BITMASK_WEIGHT))
            mstore(add(weights_, 0x60), and(shr(mul(_BITPOS_WEIGHT, 3), packedWeights), _BITMASK_WEIGHT))
            mstore(add(weights_, 0x80), and(shr(mul(_BITPOS_WEIGHT, 4), packedWeights), _BITMASK_WEIGHT))
        }
    }

    /**
     * Helper function used to efficiently pack the provided data into a single word.
     * Refer to `PackedRequest` comment for bit layout.
     */
    function _packData(
        TokenPools pool,
        uint256 tokenId,
        address account,
        uint256 weightings
    ) internal pure returns (uint256 packed) {
        assembly ("memory-safe") {
            packed := or(packed, shl(_BITPOS_EXISTS, 1))
            packed := or(packed, shl(_BITPOS_POOL, pool))
            packed := or(packed, shl(_BITPOS_TOKEN_ID, tokenId))
            packed := or(packed, shl(_BITPOS_USER, account))
            packed := or(packed, weightings)
        }
    }

    /**
     * Helper function that returns the number of tokens in the lowest supplied token pool.
     */
    function _minPoolSize() internal view returns (uint256 min) {
        min = _pools[TokenPools.COMMON].length();

        for (uint256 i = 1; i <= uint256(type(TokenPools).max); ) {
            uint256 n = _pools[TokenPools(i)].length();
            if (min > n) min = n;
            unchecked { ++i; }
        }
    }

    /**
     * Helper function used to get the pool associated with `tokenId`.
     */
    function _poolFromId(uint256 tokenId) internal view returns (TokenPools pool) {
        uint256 rank = _getRank(tokenId);

        assembly ("memory-safe") {
            pool := add(
                add(gt(_THRESHOLD_EPIC, rank), gt(_THRESHOLD_RARE, rank)),
                add(gt(_THRESHOLD_UNCOMMON, rank), gt(_THRESHOLD_COMMON, rank))
            )
        }
    }

    /**
     * Helper function used to get the rank of a given token identifier.
     */
    function _getRank(uint256 id) internal view returns (uint256 rank) {
        uint256 start = (id - 1) * 2;
        uint256 end = start + 2;
        
        bytes memory data = rankings.read(start, end);

        assembly ("memory-safe") {
            rank := shr(240, mload(add(data, 0x20)))
        }
    }

    /**
     * Helper function used to reduce bytecode size.
     */
    function _checkState(ShuffleState desiredState) private view {
        if (shuffleState != desiredState) revert InvalidState();
    }

}