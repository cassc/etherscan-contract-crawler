// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFraxStaking {
    // Struct for the stake
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function lockedStakesOf(address account)
        external
        view
        returns (LockedStake[] memory);

    function lockedLiquidityOf(address account) external view returns (uint256);

    function getAllRewardTokens() external view returns (address[] memory);

    function earned(address account) external view returns (uint256[] memory);

    function stakeLocked(uint256 liquidity, uint256 secs)
        external
        returns (bytes32);

    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) external;

    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

    function withdrawLocked(bytes32 kek_id, address destination_address)
        external
        returns (uint256);

    function getReward(address destination_address)
        external
        returns (uint256[] memory);
}