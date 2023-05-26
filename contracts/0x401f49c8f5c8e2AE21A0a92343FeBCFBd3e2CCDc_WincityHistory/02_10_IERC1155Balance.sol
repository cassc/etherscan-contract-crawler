// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155Balance {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}