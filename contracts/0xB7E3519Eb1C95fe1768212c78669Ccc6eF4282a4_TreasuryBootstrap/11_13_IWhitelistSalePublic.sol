// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWhitelistSalePublic {
  function claimQuota(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function purchase(uint256 amount, address recipient) external;

  function claimAndPurchase(
    uint256 index,
    address account,
    uint256 claimAmount,
    bytes32[] calldata merkleProof,
    uint256 purchaseAmount,
    address recipient
  ) external;

  event Purchase(
    address indexed buyer,
    address indexed recipient,
    uint256 amountIn,
    uint256 amountOut
  );
  event UpdatedMerkleRoot(bytes32 merkleRoot);
  event UpdatedPrice(uint256 price);
  event Paused(bool isPaused);
}