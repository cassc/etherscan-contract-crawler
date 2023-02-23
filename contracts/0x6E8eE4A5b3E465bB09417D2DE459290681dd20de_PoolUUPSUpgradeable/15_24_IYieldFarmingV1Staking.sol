// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IYieldFarmingV1Staking {
    struct Pool {
        uint256 size;
        bool set;
    }

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct StakingConfig {
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function initialize(StakingConfig memory cfg) external;

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns (uint256);

    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint256);

    function getCurrentEpoch() external view returns (uint128);
}