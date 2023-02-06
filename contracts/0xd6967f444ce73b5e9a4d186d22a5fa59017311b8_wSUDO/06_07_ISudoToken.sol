// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISudoToken {
    function delegate(address delegatee) external;

    function enableTransfer() external;

    function dropMultiplier() external view returns (uint256);

    function delegates(address account) external view returns (address);

    function owner() external view returns (address);
}