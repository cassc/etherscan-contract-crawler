// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev A simplified version of the Olympus staking V3 interface with methods
/// that are required for the gOHM magician contract.
interface IOlympusStakingV3Like {
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256 amount_);

    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function OHM() external view returns (address);
    function gOHM() external view returns (address);
}