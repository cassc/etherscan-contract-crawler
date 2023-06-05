// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// @author: miinded.com

interface IERC721Manager{
    function transferFrom(address from, address to, uint256 tokenId) external returns(bool);
}