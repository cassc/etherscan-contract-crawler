// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMetaStreetApesNFT {
  function mint(address _to) external returns (uint256);

  function bulkMint(uint256 _numberOfNft, address _to) external;
}