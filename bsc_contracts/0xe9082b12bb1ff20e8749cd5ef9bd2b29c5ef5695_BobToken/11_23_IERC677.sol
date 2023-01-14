// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC677 {
    function transferAndCall(address to, uint256 amount, bytes calldata data) external;
}