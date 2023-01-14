// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC677Receiver {
    function onTokenTransfer(address from, uint256 value, bytes calldata data) external returns (bool);
}