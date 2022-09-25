// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC721 {
    function transferFrom(address from, address to, uint tokenId) external;
    
    function totalSupply() external view returns (uint);

    function ownerOf(uint tokenId) external view returns (address);

    function balanceOf(address account) external view returns (uint);
}