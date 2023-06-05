// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IESMET {
    function balanceOf(address account_) external view returns (uint256);

    function lock(uint256 amount_, uint256 lockPeriod_) external;
}