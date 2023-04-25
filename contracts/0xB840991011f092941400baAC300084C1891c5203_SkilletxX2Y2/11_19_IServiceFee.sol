// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

/**
 * Skillet <> X2Y2
 * Service Fee Interface
 * https://etherscan.io/address/0xb858E4a6f81173892AD263584aa5b78F2407EE72#code
 */
interface IServiceFee {
  function getServiceFee(address _target, address _sender, address _nftAsset) external returns (uint16);
}