//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

// Interface for the ApemoArmy token
interface IApemoArmy {

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

  function operatorMint(address to, uint256 tokenId) external;
}