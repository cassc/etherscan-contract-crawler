// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint256 tokenId) external;
}