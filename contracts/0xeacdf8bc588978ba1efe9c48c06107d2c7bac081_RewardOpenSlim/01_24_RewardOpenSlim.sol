// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPoolPositionAndRewardFactorySlim} from "./interfaces/IPoolPositionAndRewardFactorySlim.sol";
import {RewardBase} from "./RewardBase.sol";

contract RewardOpenSlim is RewardBase {
    constructor(IERC20 _stakingToken, IPoolPositionAndRewardFactorySlim _rewardFactory) RewardBase(_stakingToken, _rewardFactory) {}

    function stake(uint256 amount, address account) external {
        _stake(msg.sender, amount, account);
    }

    function unstake(uint256 amount, address recipient) external {
        _unstake(msg.sender, amount, recipient);
    }

    function unstakeAll(address recipient) external {
        _unstakeAll(msg.sender, recipient);
    }

    function getReward(address recipient, uint8[] calldata rewardTokenIndices) external {
        _getReward(msg.sender, recipient, rewardTokenIndices);
    }

    function getReward(address recipient, uint8 rewardTokenIndex) external returns (uint256) {
        return _getReward(msg.sender, recipient, rewardTokenIndex);
    }
}