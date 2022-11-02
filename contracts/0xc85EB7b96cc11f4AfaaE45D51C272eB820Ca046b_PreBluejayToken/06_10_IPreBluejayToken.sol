// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPreBluejayToken {
  event Redeemed(
    address indexed owner,
    address indexed recipient,
    uint256 amount
  );

  event UpdatedMerkleRoot(bytes32 merkleRoot);

  function claimQuota(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function redeem(uint256 amount, address recipient) external;

  function redeemableTokens(address account) external view returns (uint256);

  function vestingProgress() external view returns (uint256);
}