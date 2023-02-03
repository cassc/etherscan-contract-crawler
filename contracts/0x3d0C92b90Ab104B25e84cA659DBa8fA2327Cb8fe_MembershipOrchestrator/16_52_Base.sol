// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Context} from "./Context.sol";
import "./Routing.sol" as Routing;

using Routing.Context for Context;

/// @title Base contract for application-layer
/// @author landakram
/// @notice This base contract is what all application-layer contracts should inherit from.
///  It provides `Context`, as well as some convenience functions for working with it and
///  using access control. All public methods on the inheriting contract should likely
///  use one of the modifiers to assert valid callers.
abstract contract Base {
  error RequiresOperator(address resource, address accessor);
  error ZeroAddress();

  /// @dev this is safe for proxies as immutable causes the context to be written to
  ///  bytecode on deployment. The proxy then treats this as a constant.
  Context immutable context;

  constructor(Context _context) {
    context = _context;
  }

  modifier onlyOperator(bytes4 operatorId) {
    requireOperator(operatorId, msg.sender);
    _;
  }

  modifier onlyOperators(bytes4[2] memory operatorIds) {
    requireAnyOperator(operatorIds, msg.sender);
    _;
  }

  modifier onlyAdmin() {
    context.accessControl().requireAdmin(address(this), msg.sender);
    _;
  }

  function requireAnyOperator(bytes4[2] memory operatorIds, address accessor) private view {
    if (accessor == address(0)) revert ZeroAddress();

    bool validOperator = isOperator(operatorIds[0], accessor) ||
      isOperator(operatorIds[1], accessor);

    if (!validOperator) revert RequiresOperator(address(this), accessor);
  }

  function requireOperator(bytes4 operatorId, address accessor) private view {
    if (accessor == address(0)) revert ZeroAddress();
    if (!isOperator(operatorId, accessor)) revert RequiresOperator(address(this), accessor);
  }

  function isOperator(bytes4 operatorId, address accessor) private view returns (bool) {
    return context.router().contracts(operatorId) == accessor;
  }
}