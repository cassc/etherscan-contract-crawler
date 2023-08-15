// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {IFactory} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IFactory.sol";

import {IPoolPositionSlim} from "./IPoolPositionSlim.sol";
import {IReward} from "./IReward.sol";

interface IPoolPositionAndRewardFactorySlim {
    event PoolPositionCreated(IPool pool, uint128[] binIds, uint128[] ratios, IPoolPositionSlim poolPosition, uint256 poolPositionNumber);

    event LpRewardCreated(IPoolPositionSlim poolPosition, address reward);

    event AddNewApprovedRewardToken(address rewardToken, uint256 minimumAmount);

    struct RewardInfos {
        IReward.RewardInfo[] rewardInfoList;
    }

    function allPoolPositions(uint256 poolPositionNumber) external view returns (IPoolPositionSlim poolPosition);

    function poolPositionNumber(IPoolPositionSlim poolPosition) external view returns (uint256 poolPositionNumber);

    function getLpRewardByPP(IPoolPositionSlim) external view returns (IReward);

    function poolFactory() external view returns (IFactory);

    function allPoolPositionsLength() external view returns (uint256);

    function isApprovedRewardToken(address reward) external view returns (bool);

    function minimumRewardAmount(address reward) external view returns (uint256);

    function isPoolPosition(IPoolPositionSlim poolPosition) external view returns (bool);

    function createPoolPositionAndRewards(IPool pool, uint128[] calldata binIds, uint128[] calldata ratios, bool isStatic) external returns (IPoolPositionSlim);

    function owner() external view returns (address);
}