// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Context.sol";

abstract contract InternalCalls is Context {

  uint private constant _NOT_MAKING_INTERNAL_CALLS = 1;
  uint private constant _MAKING_INTERNAL_CALLS = 2;

  uint private _internal_calls_status;

  modifier makesInternalCalls() {
    _internal_calls_status = _MAKING_INTERNAL_CALLS;
    _;
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function init() internal {
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function isInternalCall() internal view returns (bool) {
    return _internal_calls_status == _MAKING_INTERNAL_CALLS;
  }

  function isContractCall() internal view returns (bool) {
    return _msgSender() != tx.origin;
  }

  function isUserCall() internal view returns (bool) {
    return !isInternalCall() && !isContractCall();
  }
}