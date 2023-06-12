// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}