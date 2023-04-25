//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./interfaces/IXY3AddressProvider.sol";

/**
 * Skillet <> X2Y2
 * Address Provider
 * https://etherscan.io/address/0x21A619115F36dE1A71B549e9081022fe84136f65#code
 */
contract X2Y2AddressProvider {
  address public x2y2AddressProviderAddress = 0x21A619115F36dE1A71B549e9081022fe84136f65;
  IXY3AddressProvider public addressProvider = IXY3AddressProvider(x2y2AddressProviderAddress);

  function getBorrowerNoteAddress() public view returns (address borrowerNoteAddress) {
    borrowerNoteAddress = addressProvider.getBorrowerNote();
  }

  function getTransferDelegateAddress() public view returns (address transferDelegateAddress) {
    transferDelegateAddress = addressProvider.getTransferDelegate();
  }
}