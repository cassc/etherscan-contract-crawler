// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/token/ERC20/IERC20.sol";

interface IESMET is IERC20 {
    struct LockPosition {
        uint256 lockedAmount; // MET locked
        uint256 boostedAmount; // based on the `lockPeriod`
        uint256 unlockTime; // now + `lockPeriod`
    }

    function positions(uint256) external view returns (LockPosition memory);

    function MINIMUM_LOCK_PERIOD() external view returns (uint256);

    function MAXIMUM_LOCK_PERIOD() external view returns (uint256);

    function balanceOf(address account_) external view returns (uint256);

    function lock(uint256 amount_, uint256 lockPeriod_) external;

    function lockFor(address to_, uint256 amount_, uint256 lockPeriod_) external;
}