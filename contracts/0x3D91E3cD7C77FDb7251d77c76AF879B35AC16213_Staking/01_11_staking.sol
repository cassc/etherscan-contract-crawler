// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "staking/contracts/StakingERC20.sol";

/**
 * @dev Handles staking erc20 tokens
*/
contract Staking is StakingERC20 {

    constructor(
        IERC20 token,
        IERC20 rewardToken
    ) StakingERC20(token, rewardToken, 9) {

    }
}