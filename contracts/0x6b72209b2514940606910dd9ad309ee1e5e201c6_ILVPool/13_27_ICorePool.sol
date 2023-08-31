// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Stake } from "../libraries/Stake.sol";

interface ICorePool {
    function users(address _user)
        external
        view
        returns (
            uint128,
            uint128,
            uint128,
            uint248,
            uint8,
            uint256,
            uint256
        );

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user) external view returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId) external view returns (Stake.Data memory);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
}