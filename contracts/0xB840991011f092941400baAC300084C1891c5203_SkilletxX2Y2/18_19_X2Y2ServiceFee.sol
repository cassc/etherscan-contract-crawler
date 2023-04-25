//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./interfaces/IServiceFee.sol";
import "./X2Y2AddressProvider.sol";

/**
 * Skillet <> X2Y2
 * Service Fee Implementation
 * https://etherscan.io/address/0xb858E4a6f81173892AD263584aa5b78F2407EE72
 */
contract X2Y2ServiceFee is X2Y2AddressProvider {
  function calculateServiceFee(
    uint256 amount,
    address collectionAddress
  ) internal
    returns (uint256)
  {
    IServiceFee serviceFeeController = IServiceFee(addressProvider.getServiceFee());
    uint16 serviceFee = serviceFeeController.getServiceFee(
      addressProvider.getXY3(),
      address(this),
      collectionAddress
    );

    return amount * serviceFee / 10000;
  }
}