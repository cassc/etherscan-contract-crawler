// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract AdminController is ContextUpgradeable, OwnableUpgradeable {
  mapping(address => bool) private _admins;

  event AdminSet(address indexed account, bool indexed status);

  modifier onlyAdmin() {
    address sender = _msgSender();
    (bool isAdminValid, string memory errorAdminMessage) = _validateAdmin(sender);
    require(isAdminValid, errorAdminMessage);
    _;
  }

  modifier onlyAdminOrOwner() {
    address sender = _msgSender();
    (bool isAdminValid, string memory errorAdminMessage) = _validateAdminOrOwner(sender);
    require(isAdminValid, errorAdminMessage);
    _;
  }

  function setAdmin(address account, bool status) external onlyOwner {
    _setAdmin(account, status);
  }

  function renounceAdmin() external onlyAdmin {
    address sender = _msgSender();
    _setAdmin(sender, false);
  }

  function _setAdmin(address account, bool status) internal {
    require(_admins[account] != status, "AdminController: admin already set");
    _admins[account] = status;
    emit AdminSet(account, status);
  }

  function _isAdmin(address account) internal view returns (bool) {
    return _admins[account];
  }

  function _isAdminOrOwner(address account) internal view returns (bool) {
    return owner() == account || _isAdmin(account);
  }

  function _validateAdmin(address account) internal view returns (bool, string memory) {
    if (!_isAdmin(account)) {
      return (false, "AdminController: admin verification failed");
    }
    return (true, "");
  }

  function _validateAdminOrOwner(address account) internal view returns (bool, string memory) {
    if (!_isAdminOrOwner(account)) {
      return (false, "AdminController: admin or owner verification failed");
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}