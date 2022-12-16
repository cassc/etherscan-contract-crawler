// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IIndexToken is IERC20Metadata {
  struct Asset {
    address assetToken;
    uint256 amount; // per 10^18 of this token
  }

  function getFeeReceiver() external view returns (address);
  function getAssets() external view returns (Asset[] memory);
  function setAssets(Asset[] memory) external;
  function getOwner() external view returns (address);

  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function transferAsset(address asset, address to, uint256 amount) external;
}