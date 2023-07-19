// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFiatMintable {
  function mint(
    uint amount, 
    address to, 
    uint expiryDate,
    bytes calldata signature
  ) external payable;

  function reservedMint(
    uint amount,
    address to
  ) external;

  function withdrawFunds() external;

  function getPurchaseLimit() external view returns (uint16);
  function setPurchaseLimit(uint16 amount) external;
}