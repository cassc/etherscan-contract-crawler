// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ICubeX {
    function ownerOf(uint256 tokenId) external view returns (address);
}