// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVeDist {
    function claim(uint256 tokenId) external returns (uint);
}