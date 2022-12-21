// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;


interface IDepositary {

  function issuedShares() external view returns (uint256);
  function shareOf(uint256 tokenId) external view returns (uint256);
  function totalShares() external view returns (uint256);

}