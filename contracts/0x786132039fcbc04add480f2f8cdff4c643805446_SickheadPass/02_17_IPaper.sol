// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPaper {
  function getClaimIneligibilityReason(address _userWallet, uint256 _quantity, uint256 _tokenId) external view returns (string memory);
  function unclaimedSupply(uint256 _tokenId) external view returns (uint256);
  function price(uint256 _tokenId) external view returns (uint256);
  function claimTo(address _userWallet, uint256 _quantity, uint256 _tokenId) external payable;
}