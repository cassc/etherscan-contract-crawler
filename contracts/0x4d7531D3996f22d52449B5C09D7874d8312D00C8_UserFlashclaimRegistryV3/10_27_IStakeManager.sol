// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IStakeManager {
  function setFlashLoanLocking(
    address nftAsset,
    uint256 tokenId,
    bool locked
  ) external;
}