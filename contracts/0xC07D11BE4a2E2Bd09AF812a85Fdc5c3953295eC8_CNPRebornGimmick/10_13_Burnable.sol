// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface Burnable {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns(address);
}