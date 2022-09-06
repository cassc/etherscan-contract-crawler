// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** 
 *      ____  ____  ___  _  _  __     __   ____     
 *     (  _ \(  __)/ __)/ )( \(  )   / _\ (  _ \    
 *      )   / ) _)( (_ \) \/ (/ (_/\/    \ )   /    
 *     (__\_)(____)\___/\____/\____/\_/\_/(__\_)    
 *      ____  __  __ _  ____  __ _                  
 *     (_  _)/  \(  / )(  __)(  ( \                 
 *       )( (  O ))  (  ) _) /    /                 
 *      (__) \__/(__\_)(____)\_)__)                 
 *      ____  ____  ____      ____   __  ____  ____ 
 *     (  __)/ ___)(_  _)    (___ \ /  \(___ \(___ \
 *      ) _) \___ \  )(  _    / __/(  0 )/ __/ / __/
 *     (____)(____/ (__)(_)  (____) \__/(____)(____)
 * 
 * 
 * @title RegularToken (REG)
 * @dev
 * - AccessControl
 *   - minter role
 *   - pauser role
 * - ERC20
 *   - Burnable (by owner or approved)
 *   - Capped to 100 million tokens
 *   - ERC2612 support (appproval through signatures)
 *   - ERC1363 support (transfer and call)
 *   - Pausable
 * - Non upgradeable
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC1363.sol";


contract RegularToken is
    ERC20("Regular Token", "REG"),
    ERC20Burnable,
    ERC20Capped(100_000_000 ether),
    ERC20Permit("Regular Token"),
    ERC1363,
    AccessControl,
    Pausable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function transferOrMint(address to, uint256 amount) public {
        uint256 balance = balanceOf(_msgSender());

        if (balance > 0) {
            transfer(to, Math.min(amount, balance));
        }
        if (balance < amount) {
            mint(to, amount - balance);
        }
    }

    function transferFromOrMint(address from, address to, uint256 amount) public {
        uint256 balance = balanceOf(_msgSender());

        if (balance > 0) {
            transferFrom(from, to, Math.min(amount, balance));
        }
        if (balance < amount) {
            mint(to, amount - balance);
        }
    }

    function mintOrTransfer(address to, uint256 amount) public {
        uint256 mintable = Math.min(cap() - totalSupply(), amount);

        if (mintable > 0 && hasRole(MINTER_ROLE, _msgSender())) {
            mint(to, mintable);
        }
        if (amount > mintable) {
            transfer(to, amount - mintable);
        }
    }

    function mintOrTransferFrom(address from, address to, uint256 amount) public {
        uint256 mintable = Math.min(cap() - totalSupply(), amount);

        if (mintable > 0 && hasRole(MINTER_ROLE, _msgSender())) {
            mint(to, mintable);
        }
        if (amount > mintable) {
            transferFrom(from, to, amount - mintable);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1363, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}