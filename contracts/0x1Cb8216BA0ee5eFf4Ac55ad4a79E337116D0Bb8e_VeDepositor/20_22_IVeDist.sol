// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVeDist {
    function claim(uint _tokenId) external returns (uint);
}