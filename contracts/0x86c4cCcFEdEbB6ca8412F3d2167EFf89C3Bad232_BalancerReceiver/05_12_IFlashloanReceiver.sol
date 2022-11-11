// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashloanReceiver {
    function getFee() external view returns (uint256 fee);

    function flashLoan(address token, uint256 amount) external;
}