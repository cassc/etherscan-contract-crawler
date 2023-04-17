// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../libs/Errors.sol";

abstract contract OnlyDelegateCall {
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
  address private immutable self = address(this);

  modifier onlyDelegateCall() {
    _require(address(this) != self, Errors.DELEGATE_CALL_ONLY);
    _;
  }
}