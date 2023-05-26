// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IGearToken } from "./interfaces/IGearToken.sol";

address constant GEAR_ETH_GAUGE = 0x37Efc3f05D659B30A83cf0B07522C9d08513Ca9d;
address constant GEARBOX_TREASURY = 0x7b065Fcb0760dF0CEA8CFd144e08554F3CeA73D1;
address constant GEAR_TOKEN = 0xBa3335588D9403515223F109EdC4eB7269a9Ab5D;
uint256 constant WEEK = 7 days;

interface ICurveGauge {
    function deposit_reward_token(address _reward_token, uint256 _amount) external;
}

contract GearGaugeDistributor {
    using Address for address;

    event NewWeeklyRewardAmount(uint256 indexed reward);

    event RewardsDistributed(uint256 indexed rewardsAdded);

    uint128 public weeklyReward;
    uint128 public lastUpdated;

    modifier onlyTreasury() {
        require(msg.sender == GEARBOX_TREASURY, "Can only be called by Gearbox Treasury");
        _;
    }

    function setWeeklyRewardAmount(uint256 reward) external onlyTreasury {
        weeklyReward = uint128(reward);
        emit NewWeeklyRewardAmount(reward);
    }

    function execute(address target, bytes memory data)
        external
        onlyTreasury
        returns (bytes memory)
    {
        return target.functionCall(data);
    }

    function refreshGaugeRewards() external {

        uint256 period = block.timestamp - uint256(lastUpdated) > WEEK ? WEEK : block.timestamp - uint256(lastUpdated);
        uint256 rewardsToAdd = uint256(weeklyReward) * period / WEEK;

        lastUpdated = uint128(block.timestamp);

        require(rewardsToAdd > 0, "Nothing to add");

        IGearToken(GEAR_TOKEN).approve(GEAR_ETH_GAUGE, rewardsToAdd + 1);
        ICurveGauge(GEAR_ETH_GAUGE).deposit_reward_token(GEAR_TOKEN, rewardsToAdd);

        emit RewardsDistributed(rewardsToAdd);
    }
}