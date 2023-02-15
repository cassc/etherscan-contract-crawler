// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../interfaces/IAccessManager.sol";

/// @title LibIMPT
/// @author Github: Labrys-Group
/// @dev Library for implementing frequently re-used functions, errors, events and data structures / state in IMPT
library LibIMPT {
  //######################
  //#### PUBLIC STATE ####

  bytes32 public constant IMPT_ADMIN_ROLE = keccak256("IMPT_ADMIN_ROLE");
  bytes32 public constant IMPT_BACKEND_ROLE = keccak256("IMPT_BACKEND_ROLE");
  bytes32 public constant IMPT_APPROVED_DEX = keccak256("IMPT_APPROVED_DEX");
  bytes32 public constant IMPT_MINTER_ROLE = keccak256("IMPT_MINTER_ROLE");
  bytes32 public constant IMPT_SALES_MANAGER = keccak256("IMPT_SALES_MANAGER");
  bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);

  //################
  //#### ERRORS ####

  ///@dev Thrown when _checkZeroAddress is called with the zero addres.
  error CannotBeZeroAddress();
  ///@dev Thrown when an auth signature from the IMPT back-end is invalid
  error InvalidSignature();
  ///@dev Thrown when an auth signature from the IMPT back-end  has expired
  error SignatureExpired();

  /// @dev Thrown when a custom checkRole function is used and the caller does not have the required role
  error MissingRole(bytes32 _role, address _account);

  ///@dev Emitted when the IMPT treasury changes
  event IMPTTreasuryChanged(address _implementation);

  //############################
  //#### INTERNAL FUNCTIONS ####

  ///@dev Internal function that checks if an address is zero and reverts if it is.
  ///@param _address The address to check.
  function _checkZeroAddress(address _address) internal pure {
    if (_address == address(0)) {
      revert CannotBeZeroAddress();
    }
  }

  function _hasIMPTRole(
    bytes32 _role,
    address _address,
    IAccessManager _AccessManager
  ) internal view {
    if (!(_AccessManager.hasRole(_role, _address))) {
      revert MissingRole(_role, msg.sender);
    }
  }
}