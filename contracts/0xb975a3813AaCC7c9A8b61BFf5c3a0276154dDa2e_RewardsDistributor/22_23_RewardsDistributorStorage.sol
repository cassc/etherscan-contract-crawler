// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IRewardsDistributor.sol";

abstract contract RewardsDistributorStorageV1 is IRewardsDistributor {
    struct TokenState {
        uint224 index; // The last updated index
        uint32 timestamp; // The timestamp of the latest index update
    }

    /**
     * @notice The token to reward
     */
    IERC20 public override rewardToken;

    /**
     * @notice Track tokens for reward
     */
    IERC20[] public override tokens;

    /**
     * @notice The amount of token distributed for each token per second
     */
    mapping(IERC20 => uint256) public override tokenSpeeds;

    /**
     * @notice The reward state for each token
     */
    mapping(IERC20 => TokenState) public override tokenStates;

    /**
     * @notice The supply index for each token for each account as of the last time they accrued token
     */
    mapping(IERC20 => mapping(address => uint256)) public override accountIndexOf;

    /**
     * @notice The token accrued but not yet transferred to each user
     */
    mapping(address => uint256) public override tokensAccruedOf;
}