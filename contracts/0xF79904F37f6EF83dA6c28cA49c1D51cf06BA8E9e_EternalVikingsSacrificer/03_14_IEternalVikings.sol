// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IEternalVikings {
   function mint(address receiver, uint256 amount) external;
   function totalSupply() external view returns (uint256);
   function setStakingStatusOfToken(uint256 tokenId, bool isStaked) external;
   function stakingOwner(uint256 tokenId) external view returns (address);
   function tokensOfOwner(address owner) external view returns (uint256[] memory);
   function balanceOf(address user) external view returns (uint256);
   function tokenToStaked(uint256 token) external view returns (uint256);
}