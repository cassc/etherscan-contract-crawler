// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract MinterAccessControl {

  /// @dev a list of minter role, and only minter can mint nft
  mapping(address => bool) public minters;

  /**
    * @dev Fired in grantMinterRole()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param account an address which is granted minter role
    */
  event MinterRoleGranted(address indexed sender, address indexed account);

  /**
    * @dev Fired in revokeMinterRole()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param account an address which is revoked minter role
    */
  event MinterRoleRevoked(address indexed sender, address indexed account);

  /**
    * @notice Service function to grant minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is granted minter role
    */
  function _grantMinterRole(address addr_) internal virtual {
    require(addr_ != address(0), "invalid address");
    minters[addr_] = true;
    emit MinterRoleGranted(msg.sender, addr_);
  }

  /**
    * @notice Service function to revoke minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is revorked minter role
    */
  function _revokeMinterRole(address addr_) internal virtual {
    require(addr_ != address(0), "invalid address");
    minters[addr_] = false;
    emit MinterRoleRevoked(msg.sender, addr_);
  }

  /**
    * @dev Modifier that checks that an account has a minter role.
    *
    */
  modifier onlyMinter() {
      require(minters[msg.sender] == true, "permission denied");
      _;
  }

}