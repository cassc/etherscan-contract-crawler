// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;


/**
 * @dev The ManyToOneImplementationHolder stores an upgradeable implementation address
 * in storage, which many-to-one proxies query at execution time to determine which
 * contract to delegate to.
 *
 * The manager can upgrade the implementation address by calling the holder with the
 * abi-encoded address as calldata. If any other account calls the implementation holder,
 * it will return the implementation address.
 *
 * This pattern was inspired by the DharmaUpgradeBeacon from 0age
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/upgradeability/smart-wallet/DharmaUpgradeBeacon.sol
 */
contract ManyToOneImplementationHolder {
/* ---  Storage  --- */
  address internal immutable _manager;
  address internal _implementation;

/* ---  Constructor  --- */
  constructor() public {
    _manager = msg.sender;
  }

  /**
   * @dev Fallback function for the contract.
   *
   * Used by proxies to read the implementation address and used
   * by the proxy manager to set the implementation address.
   *
   * If called by the owner, reads the implementation address from
   * calldata (must be abi-encoded) and stores it to the first slot.
   *
   * Otherwise, returns the stored implementation address.
   */
  fallback() external payable {
    if (msg.sender != _manager) {
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    }
    assembly { sstore(0, calldataload(0)) }
  }
}