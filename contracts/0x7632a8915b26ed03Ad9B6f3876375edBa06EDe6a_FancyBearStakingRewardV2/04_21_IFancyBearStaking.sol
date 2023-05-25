// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFancyBearStaking {    
     function getOwnerOf(uint256 _tokenId) external view returns (address);
}