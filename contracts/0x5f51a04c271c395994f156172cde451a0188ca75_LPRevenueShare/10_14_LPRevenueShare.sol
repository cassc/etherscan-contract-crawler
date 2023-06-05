// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './RevenueShareBase.sol';
import '../Constants.sol' as Constants;

contract LPRevenueShare is RevenueShareBase {
    constructor(address _lockToken, uint256 _lockDuration) RevenueShareBase(_lockDuration) {
        lockToken = IERC20(_lockToken);
    }

    /**
     * @dev Add rewards token to the list
     * @param _rewardsToken is the reward token address
     */
    function addReward(address _rewardsToken) external override onlyOwner {
        require(_rewardsToken != address(lockToken), 'Rewards token is staking token');

        require(
            rewardData[_rewardsToken].lastUpdateTime == 0,
            'This token already exists as a reward token'
        );

        require(
            rewardTokens.length < Constants.LIST_SIZE_LIMIT_DEFAULT,
            'Reward token list: size limit exceeded'
        );

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
    }

    /**
     * @dev lock `lockToken` tokens to receive rewards in USDC and USDT
     * 50% can be from a farm or just a simple lock from the user
     * @param _amount is the number of `lockToken` tokens
     */
    function lock(uint256 _amount) external whenNotPaused {
        _lock(_amount, msg.sender);
    }

    /**
     * @dev return unseen amount of tokens
     * @param _token is the provided token address
     * @param _balance is the provided current balance for the token
     */
    function _unseen(
        address _token,
        uint256 _balance
    ) internal view override returns (uint256 unseen) {
        unseen = IERC20(_token).balanceOf(address(this)) - _balance;
    }
}