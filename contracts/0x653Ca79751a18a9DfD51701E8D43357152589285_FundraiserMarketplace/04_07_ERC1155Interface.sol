// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155Token {
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function mint(uint256 amount, address to) external returns(uint256);
}