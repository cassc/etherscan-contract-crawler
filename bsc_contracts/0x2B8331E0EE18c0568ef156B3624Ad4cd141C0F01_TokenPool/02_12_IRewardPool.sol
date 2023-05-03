// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";

struct RewardPoolConfiguration {
    address stakedToken;
    address rewardToken;
    address admin;
    address projectTaxAddress;
    address taxAddress;
    uint256 rewardPerBlock;
    uint256 startBlock;
    uint256 bonusEndBlock;
    uint256 poolLimitPerUser;
    uint256 tax;
    uint256 projectTax;
}

interface IRewardPool {
    function vaultAddress() external view returns (address);
    function initialize(RewardPoolConfiguration memory config) external;
}