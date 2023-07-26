//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** solhint-disable */

/**
*  NOTE - this is the non-transferrable vault version!
*/

interface IConvexBooster {
    function createVault(uint256 _pid) external returns (address);
}

interface IConvexFeeRegistry {
    function totalFees() external view returns (uint256);
}

interface IConvexVault {
    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);
    function stakeLockedConvexToken(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);
    function stakeLocked(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;
    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;
    function lockAdditionalConvexToken(bytes32 _kek_id, uint256 _addl_liq) external;
    function withdrawLocked(bytes32 _kek_id) external;
    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

    function earned() external view  returns (address[] memory token_addresses, uint256[] memory total_earned);
    function getReward() external;
    function getReward(bool _claim) external;
    function getReward(bool _claim, address[] calldata _rewardTokenList) external;

    function stakingAddress() external view returns (address);
    function stakingToken() external view returns (address);
    function curveLpToken() external view returns (address);
    function convexDepositToken() external view returns (address);
}