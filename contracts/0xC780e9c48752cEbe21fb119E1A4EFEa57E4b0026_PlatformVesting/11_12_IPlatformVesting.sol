// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPlatformVesting {
    function amountForClaim(address wallet, uint256 timestampInSeconds) external view returns (uint256 amount);
    function claim(address wallet) external;
}