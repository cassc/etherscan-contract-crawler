//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OwnPauseBase is Ownable, Pausable {
  mapping(address => bool) public _authorizedAddressList;

  event EvtRevokeAuthorized(address auth_);
  event EvtGrantAuthorized(address auth_);
  
  modifier isAuthorized() {
    require(
      msg.sender == owner() || _authorizedAddressList[msg.sender] == true,
      "not authorized"
    );
    _;
  }

  modifier isOwner() {
    require(msg.sender == owner(), "not owner");
    _;
  }

  function grantAuthorized(address auth_) external isOwner {
    _authorizedAddressList[auth_] = true;
    emit EvtGrantAuthorized(auth_);
  }

  function revokeAuthorized(address auth_) external isOwner {
    _authorizedAddressList[auth_] = false;
    emit EvtRevokeAuthorized(auth_);
  }

  function checkAuthorized(address auth_) public view returns (bool) {
    return auth_ == owner() || _authorizedAddressList[auth_] == true;
  }

  function unpause() external isOwner {
    _unpause();
  }

  function pause() external isOwner {
    _pause();
  }
}