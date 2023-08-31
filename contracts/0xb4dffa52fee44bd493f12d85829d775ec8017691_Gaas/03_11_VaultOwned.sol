// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "./Ownable.sol";

contract VaultOwned is Ownable {
    
  address internal _vault;

  function setVault( address vault_ ) external onlyOwner() returns ( bool ) {
    _vault = vault_;

    return true;
  }

  /**
   * @dev Returns the address of the current vault.
   */
  function vault() public view returns (address) {
    return _vault;
  }

  /**
   * @dev Throws if called by any account other than the vault.
   */
  modifier onlyVault() {
    require( _vault == msg.sender, "VaultOwned: caller is not the Vault" );
    _;
  }

}