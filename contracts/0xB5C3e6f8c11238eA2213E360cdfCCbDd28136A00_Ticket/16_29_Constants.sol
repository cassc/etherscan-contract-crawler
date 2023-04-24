// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

abstract contract Constants {
    /**
     * @notice Maximum value is equal to 500 because Chainlink can provide only
     *         500 random numbers per one request.
     */
    uint256 public constant MAX_DISTRIBUTION_LENGTH = 500;

    /**
     * @notice Maximum value is equal to 256 because DrawRingBuffer can store
     *         only 256 draws maximum. An oldest draws always will be rewritten
     *         by a newest one.
     */
    uint256 public constant MAX_DRAW_IDS_LENGTH = 256;

    /**
     * @notice Maximum value is equal to 10000 because it is no reason to do it
     *         greater.
     */
    uint256 public constant MAX_TIMESTAMPS_LENGTH = 10_000;

    /**
     * @notice Maximum value is equal to 1000 because it is no reason to do it
     *         greater.
     */
    uint256 public constant MAX_TOKEN_IDS_LENGTH = 1_000;

    /**
     * @notice Maximum value is equal to 1000 because it is no reason to do it
     *         greater.
     */
    uint256 public constant MAX_EPOCH_IDS_LENGTH = 1_000;
}