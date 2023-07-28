// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import {ERC20, ERC20MintableBurnableByMinter} from "../../lib/ERC20MintableBurnableByMinter.sol";

contract SgETH is ERC20MintableBurnableByMinter {
  constructor() ERC20MintableBurnableByMinter("SharedStake Governed Staked Ether", "sgETH") {
    // Set the admin of the minter role; this causes the grant and revole role fns to gaurd to this admin role
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  // Adds whitelisted minters - only callable by DEFAULT_ADMIN_ROLE enforced in OZ dep
  function addMinter(address minterAddress) external {
    require(minterAddress != address(0), "Zero address detected");
    grantRole(MINTER, minterAddress);
  }

  // Remove a minter - only callable by DEFAULT_ADMIN_ROLE enforced internally
  function removeMinter(address minterAddress) external {
    // oz uses maps so 0 address will return true but does not break anything
    revokeRole(MINTER, minterAddress);
  }

  // Transfer ownership of who can add/rm minters
  function transferOwnership(address newOwner) external {
    _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender); // permission gaurded via revert if called lacks role
  }
}