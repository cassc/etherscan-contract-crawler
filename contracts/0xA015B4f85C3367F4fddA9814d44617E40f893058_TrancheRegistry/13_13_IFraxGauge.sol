pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/curve/IFraxGauge.sol)

// ref: https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Staking/FraxUnifiedFarm_ERC20.sol

interface IFraxGauge {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function withdrawLocked(bytes32 kek_id, address destination_address) external;

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
    function getAllRewardTokens() external view returns (address[] memory);
    function getReward(address destination_address) external returns (uint256[] memory);

    function stakerSetVeFXSProxy(address proxy_address) external;
    function stakerToggleMigrator(address migrator_address) external;

    function lock_time_min() external view returns (uint256);
    function lock_time_for_max_multiplier() external view returns (uint256);
}