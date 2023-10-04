// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title Decommissionable.sol. Simple contract to implement a decommission 'kill switch'
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.21;

import {IErrors} from "./IErrors.sol";
import {Revert} from "./Revert.sol";

abstract contract Decommissionable is IErrors, Revert {
  bool internal _decommissioned;

  /**
   * @dev {notWhenDecommissioned}
   *
   * Throws if the contract has been decommissioned
   */
  modifier notWhenDecommissioned() {
    if (_decommissioned) {
      _revert(ContractIsDecommissioned.selector);
    }
    _;
  }

  /**
   * @dev Internal method to set the decommissioned flag. Should be called
   * by an external method with access control (e.g. ownable etc.)
   */
  function _decommission() internal {
    _decommissioned = true;
  }
}