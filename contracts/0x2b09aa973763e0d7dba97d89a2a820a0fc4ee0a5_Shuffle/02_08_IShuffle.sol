// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IShuffle {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * The expected state value does not match the current state.
     */
    error InvalidState();

    /**
     * The provided array has no length.
     */
    error ZeroLengthArray();

    /**
     * The sum of the provided array does not match the expected value.
     */
    error WeightMismatch();

    /**
     * A non-existing request is attempting to be fulfilled by the Oracle.
     */
    error RequestNotFound();

    /**
     * The new number of pending requests will outsize the lowest supplied token pool.
     */
    error InvalidPoolSize();

    /**
     * The data size provided does not match the expected data size.
     */
    error InvalidDataSize();

    /**
     * Failed to add a token to the EnumerableSet.
     */
    error AddFailed();

    /**
     * Failed to remove a token from the EnumerableSet.
     */
    error RemoveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ENUMS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Used to track the shuffling state of the contract.
     */
    enum ShuffleState {
        INACTIVE,
        ACTIVE
    }

    /**
     * Used to reference a token pool that a token should be deposited
     * or withdrawn from.
     */
    enum TokenPools {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * This struct imitates the unpacked values from `PackedRequest.data`.
     */
    struct Request {
        bool fulfilled;
        bool exists;
        TokenPools pool;
        uint256 tokenId;
        address user;
        uint256[5] weights;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Shuffled(address indexed user, uint256 tokenIn, uint256 tokenOut);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to shuffle an Isekai Meta token.
     */
    function shuffle(uint256 tokenId) external;

    /**
     * Function used to add reward tokens to the shuffler.
     */
    function addRewardTokens(uint256[] calldata tokenIds) external;

    /**
     * Function used to remove reward tokens from the shuffler.
     */
    function removeRewardTokens(uint256[] calldata tokenIds) external;

    /** 
     * Function used to withdraw reward tokens from the shuffler without pool updates.
     */
    function emergencyWithdraw(uint256[] calldata tokenIds) external;

    /**
     * Function used to set a new `shuffleState` value.
     */
    function setShuffleState(ShuffleState newShuffleState) external;

    /**
     * Function used to view all tokens in `pool`. 
     */
    function getTokensInPool(TokenPools pool) external view returns (uint256[] memory);

    /**
     * Function used to view the number of tokens in `pool`.
     */
    function getAmountOfTokensInPool(TokenPools pool) external view returns (uint256);

    /**
     * Function used to check if `tokenId` is in `pool`.
     */
    function isTokenInPool(TokenPools pool, uint256 tokenId) external view returns (bool);

    /**
     * Function used to check the weights associated with `pool`.
     */
    function weights(TokenPools pool) external view returns (uint256[5] memory);

    /**
     * Function used to view the token pool associated with `tokenId`.
     */
    function poolFromId(uint256 tokenId) external view returns (TokenPools);

    /**
     * Function used to view the rank associated with `tokenId`.
     */
    function getRank(uint256 tokenId) external view returns (uint256);

    /**
     * Function used to view an unpacked request for `requestId`.
     */
    function requests(uint256 requestId) external view returns (Request memory);

}