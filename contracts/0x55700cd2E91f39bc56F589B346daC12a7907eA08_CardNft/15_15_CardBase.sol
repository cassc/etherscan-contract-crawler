//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract CardBase is Ownable, Pausable {
  // List of _authorizedAddressList addresses
  mapping(address => bool) internal _authorizedAddressList;

  event EventGrantAuthorized(address auth_);
  event EventRevokeAuthorized(address auth_);

  modifier isOwner() {
    require(_msgSender() == owner(), "CardBase: not owner");
    _;
  }

  modifier isAuthorized() {
    require(
      _msgSender() == owner() || _authorizedAddressList[_msgSender()] == true,
      "CardBase: unauthorized"
    );
    _;
  }

  function grantAuthorized(address auth_) external isOwner {
    require(auth_ != address(0), "CardBase: invalid auth_ address ");

    _authorizedAddressList[auth_] = true;

    emit EventGrantAuthorized(auth_);
  }

  function revokeAuthorized(address auth_) external isOwner {
    require(auth_ != address(0), "CardBase: invalid auth_ address ");

    _authorizedAddressList[auth_] = false;

    emit EventRevokeAuthorized(auth_);
  }

  function pause() external isOwner {
    _pause();
  }

  function unpause() external isOwner {
    _unpause();
  }
}