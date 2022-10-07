// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IYieldWolf {
    function operators(address addr) external returns (bool);

    function feeAddress() external returns (address);

    function stakedTokens(uint256 pid, address user) external view returns (uint256);
}