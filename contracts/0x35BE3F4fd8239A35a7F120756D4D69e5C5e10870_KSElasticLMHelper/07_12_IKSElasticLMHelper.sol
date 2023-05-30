// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKSElasticLMHelper {
  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (bool);

  /// @dev use virtual to be overrided to mock data for fuzz tests
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) external view returns (uint128);

  function getSignedFee(address nftContract, uint256 nftId) external view returns (int256);

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (int256);

  function getLiq(address nftContract, uint256 nftId) external view returns (uint128);

  function getPair(address nftContract, uint256 nftId) external view returns (address, address);
}