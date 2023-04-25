// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

/**
 * Skillet <> X2Y2
 * X2Y2 Address Provider Interface
 * https://etherscan.io/address/0x21A619115F36dE1A71B549e9081022fe84136f65#code
 */
interface IXY3AddressProvider {
  function getBorrowerNote() external view returns (address);
  function getTransferDelegate() external view returns (address);
  function getXY3() external view returns (address);
  function getServiceFee() external view returns (address);
}