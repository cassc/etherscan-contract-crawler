// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol';

interface IGMTransferController is IERC165, IAccessControlUpgradeable {
  function canTokenBeTransferred(
    address collectionAddress,
    address from,
    address to,
    uint256 tokenId
  ) external view returns (bool);

  function bypassTokenId(address collectionAddress, uint256 tokenId) external;

  function removeBypassTokenId(address collectionAddress, uint256 tokenId) external;
}