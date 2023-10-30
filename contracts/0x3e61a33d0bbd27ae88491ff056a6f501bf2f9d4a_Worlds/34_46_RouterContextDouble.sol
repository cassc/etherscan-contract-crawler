// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../libraries/RouteCallLibrary.sol";

error RouterContextDouble_Address_Is_Not_A_Contract();

/**
 * @title Enables trusted contracts to override the usual msg.sender address.
 * @author HardlyDifficult
 */
abstract contract RouterContextDouble is ContextUpgradeable {
  using AddressUpgradeable for address;

  address private immutable approvedRouterA;
  address private immutable approvedRouterB;

  constructor(address routerA, address routerB) {
    if (!routerA.isContract()) {
      revert RouterContextDouble_Address_Is_Not_A_Contract();
    }
    if (!routerB.isContract()) {
      revert RouterContextDouble_Address_Is_Not_A_Contract();
    }

    approvedRouterA = routerA;
    approvedRouterB = routerB;
  }

  /**
   * @notice Returns the contracts which are able to override the msg.sender address.
   * @return routerA The address of the 1st trusted router.
   * @return routerB The address of the 2nd trusted router.
   */
  function getApprovedRouterAddresses() external view returns (address routerA, address routerB) {
    routerA = approvedRouterA;
    routerB = approvedRouterB;
  }

  /**
   * @notice Gets the sender of the transaction to use, overriding the usual msg.sender if the caller is a trusted
   * router.
   * @dev If the msg.sender is a trusted router contract, then the last 20 bytes of the calldata represents the
   * authorized sender to use.
   * If this is used for a call that was not routed with `routeCallTo`, the address returned will be incorrect (and
   * may be address(0)).
   */
  function _msgSender() internal view virtual override returns (address sender) {
    sender = super._msgSender();
    if (sender == approvedRouterA || sender == approvedRouterB) {
      sender = RouteCallLibrary.extractAppendedSenderAddress();
    }
  }

  // This mixin uses 0 slots.
}