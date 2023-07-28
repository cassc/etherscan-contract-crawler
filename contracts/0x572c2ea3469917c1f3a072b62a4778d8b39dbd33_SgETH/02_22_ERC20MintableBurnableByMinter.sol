//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from"@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Parent contract for sgETH.sol
/** @notice Based on ERC20PermitPermissionedMint - base contract for frxETH. 
    Changed to reduce code footprint and rely on OZ primitives instead
    Using ownable and OZ AccessControl for minter management and standard underlying events instead of extra custom events
    Also includes a list of authorized minters 
    Steps: 1. Deploy it. 2. Set new sgETH minter 3. Transfer ownership to multisig timelock 4. confirm accept ownership from timelock */
/// @dev Adheres to EIP-712/EIP-2612 and can use permits
contract ERC20MintableBurnableByMinter is ERC20Burnable, ERC20Permit, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");

    /* ========== CONSTRUCTOR ========== */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERC20Permit(_name) AccessControl() {}

    /* ========== RESTRICTED FUNCTIONS ========== */
    /// @notice burnFrom Used by minters when user redeems
    /// @param addr The address to burn from
    /// @param amt The amount to burn
    function burnFrom(address addr, uint256 amt) public override onlyRole(MINTER) {
        super.burnFrom(addr, amt);
    }

    function burn(address addr, uint256 amt) public onlyRole(MINTER) {
        super._burn(addr, amt);
    }

    /// @notice mint This function is what other minters will call to mint new tokens
    /// @param addr The address to mint to 
    /// @param amt The amount to mint 
    function mint(address addr, uint256 amt) public onlyRole(MINTER) {
        _mint(addr, amt);
    }
}