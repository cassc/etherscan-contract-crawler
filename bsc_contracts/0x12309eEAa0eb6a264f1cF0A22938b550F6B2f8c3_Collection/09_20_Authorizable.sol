// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {
  mapping(address => bool) public authorized;

  /**
   * Modifier to restrict access to only authorized addresses or the owner
   */
  modifier onlyAuthorized() {
    require(
      authorized[msg.sender] || owner() == msg.sender,
      "Authorizable: Must be access permissions"
    );
    _;
  }

  /**
   * Add an address to the list of authorized addresses
   *
   * @dev Only the contract owner can call this function
   * @param _toAdd -> The address to add to list of authorized addresses
   */
  function addAuthorized(address _toAdd) public onlyOwner {
    require(_toAdd != address(0), "Authorizable: Rejected null address");
    authorized[_toAdd] = true;
  }

  /**
   * Remove an address from the list of authorized addresses
   *
   * @dev Only the contract owner can call this function
   * @param _toRemove -> The address to remove from list of authorized addresses
   */
  function removeAuthorized(address _toRemove) public onlyOwner {
    require(_toRemove != address(0), "Authorizable: Rejected null address");
    require(_toRemove != msg.sender, "Authorizable: Rejected self remove");
    authorized[_toRemove] = false;
  }
}