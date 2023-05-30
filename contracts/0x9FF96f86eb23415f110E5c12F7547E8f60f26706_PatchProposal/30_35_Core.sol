// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract Core {
    /// @notice Locked token balance for each account
    mapping(address => uint256) public lockedBalance;
}