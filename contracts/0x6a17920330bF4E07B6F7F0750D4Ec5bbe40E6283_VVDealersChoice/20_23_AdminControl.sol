// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IAdminControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AdminControl is AccessControl {

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(ADMIN_ROLE, _msgSender());
  }

  // ========== Modifiers ==========

  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, _msgSender()), "Caller is not an admin");
    _;
  }

  /**
  * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAdminControl).interfaceId || super.supportsInterface(interfaceId);
  }
}