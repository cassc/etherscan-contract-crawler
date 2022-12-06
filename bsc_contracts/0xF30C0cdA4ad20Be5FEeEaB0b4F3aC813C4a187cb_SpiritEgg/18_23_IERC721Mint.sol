// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Mint {
    function mint(address to, uint256 tokenId) external;
}