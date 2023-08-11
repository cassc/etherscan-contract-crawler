// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IAuraMinter {
    function inflationProtectionTime() external view returns (uint256);
}