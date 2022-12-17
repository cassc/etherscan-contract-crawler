// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

abstract contract Secured {
  address public owner;
  address public admin;

  // Modifiers -----------------------------------------------------------------
  modifier onlyOwner() {
    require(_msgSender() == owner, "OWN");
    _;
  }

  modifier onlyAdmin() {
    require(_msgSender() == admin || _msgSender() == owner, "ADM");
    _;
  }

  // Internal functions ----------------------------------------------------------------
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  // Modify functions ------------------------------------------------------------
  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function changeAdmin(address newAdmin) public onlyOwner {
    admin = newAdmin;
  }
}