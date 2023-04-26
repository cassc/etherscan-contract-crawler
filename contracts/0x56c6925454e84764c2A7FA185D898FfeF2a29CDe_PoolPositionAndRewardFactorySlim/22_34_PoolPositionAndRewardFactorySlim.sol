// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {IFactory} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IFactory.sol";

import {PoolPositionBaseDeployerSlim} from "./PoolPositionStaticDeployerSlim.sol";
import {PoolPositionDynamicDeployerSlim} from "./PoolPositionDynamicDeployerSlim.sol";
import {RewardOpenSlim} from "../RewardOpenSlim.sol";

import {IPoolPositionSlim} from "../interfaces/IPoolPositionSlim.sol";
import {IPoolPositionAndRewardFactorySlim} from "../interfaces/IPoolPositionAndRewardFactorySlim.sol";
import {IReward} from "../interfaces/IReward.sol";

/// @notice factory that creates a tuple of two contracts: 1) a reward for LPs;
//2) a pool position.
contract PoolPositionAndRewardFactorySlim is IPoolPositionAndRewardFactorySlim, Ownable, Multicall {
    IFactory public immutable poolFactory;

    IPoolPositionSlim[] public allPoolPositions;
    mapping(IPoolPositionSlim => bool) public isPoolPosition;

    mapping(IPoolPositionSlim => uint256) public poolPositionNumber;

    error MustBeFactoryPool();

    ////////////////////////////////////////////////
    //   Gov Values
    ////////////////////////////////////////////////

    mapping(address => bool) public isApprovedRewardToken;
    mapping(address => uint256) public minimumRewardAmount;

    constructor(IFactory _poolFactory) {
        poolFactory = _poolFactory;
    }

    ////////////////////////////////////////////////
    //   Admin Functions
    ////////////////////////////////////////////////

    function addNewApprovedRewardToken(address rewardToken, uint256 minimumAmount) external onlyOwner {
        _addNewApprovedRewardToken(rewardToken, minimumAmount);
    }

    ////////////////////////////////////////////////
    //   View Functions
    ////////////////////////////////////////////////

    function owner() public view override(IPoolPositionAndRewardFactorySlim, Ownable) returns (address) {
        return Ownable.owner();
    }

    function allPoolPositionsLength() external view returns (uint) {
        return allPoolPositions.length;
    }

    ////////////////////////////////////////////////
    //   Pool Position
    ////////////////////////////////////////////////

    /// @dev creates pool position and corresponding rewards contracts
    function createPoolPositionAndRewards(IPool pool, uint128[] calldata binIds, uint128[] calldata ratios, bool isStatic) external returns (IPoolPositionSlim poolPosition) {
        if (!poolFactory.isFactoryPool(pool)) revert MustBeFactoryPool();

        uint256 _poolPositionNumber = allPoolPositions.length;

        poolPosition = isStatic ? PoolPositionBaseDeployerSlim.deploy(pool, binIds, ratios, _poolPositionNumber) : PoolPositionDynamicDeployerSlim.deploy(pool, binIds, ratios, _poolPositionNumber);

        allPoolPositions.push(poolPosition);
        poolPositionNumber[poolPosition] = _poolPositionNumber;
        isPoolPosition[poolPosition] = true;

        _createLpReward(poolPosition);
        emit PoolPositionCreated(pool, binIds, ratios, poolPosition, _poolPositionNumber);
    }

    function _addNewApprovedRewardToken(address rewardToken, uint256 minimumAmount) internal {
        isApprovedRewardToken[rewardToken] = true;
        minimumRewardAmount[rewardToken] = minimumAmount;
        emit AddNewApprovedRewardToken(rewardToken, minimumAmount);
    }

    ////////////////////////////////////////////////
    //   LP Rewards
    ////////////////////////////////////////////////

    /// @notice PoolPosition -> reward
    mapping(IPoolPositionSlim => IReward) public getLpRewardByPP;

    /// @notice reward address -> bool
    mapping(IReward => bool) public isFactoryLpReward;

    function getLpRewardListInfoByPP(IPoolPositionSlim poolPosition) external view returns (IReward.RewardInfo[] memory rewardInfo) {
        rewardInfo = getLpRewardByPP[poolPosition].rewardInfo();
    }

    function getLpRewardListInfo(IReward[] memory rewardList) external view returns (RewardInfos[] memory rewardInfos) {
        uint256 length = rewardList.length;
        rewardInfos = new RewardInfos[](length);

        for (uint256 i; i < length; i++) {
            rewardInfos[i].rewardInfoList = rewardList[i].rewardInfo();
        }
    }

    function _createLpReward(IPoolPositionSlim poolPosition) internal returns (IReward reward) {
        reward = new RewardOpenSlim(IERC20(address(poolPosition)), this);

        isFactoryLpReward[reward] = true;

        getLpRewardByPP[poolPosition] = reward;

        emit LpRewardCreated(poolPosition, address(reward));
    }
}