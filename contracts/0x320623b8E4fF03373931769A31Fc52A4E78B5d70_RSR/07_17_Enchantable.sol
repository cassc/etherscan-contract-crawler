// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Spell.sol";

/**
 * @title Enchantable
 * @dev A very simple mixin that enables the spell-casting pattern.
 */
abstract contract Enchantable is Ownable {
    address private _mage;

    event MageChanged(address oldMage, address newMage);
    event SpellCast(address indexed addr);

    modifier onlyAdmin() {
        require(_msgSender() == _mage || _msgSender() == owner(), "only mage or owner");
        _;
    }

    /// At the end of a transaction, mage() should *always* be 0!
    function mage() public view returns (address) {
        return _mage;
    }

    /// Grants mage to a Spell, casts the spell, and restore mage
    function castSpell(Spell spell) external onlyOwner {
        _grantMage(address(spell));
        spell.cast();
        _grantMage(address(0));
        emit SpellCast(address(spell));
    }

    function _grantMage(address mage_) private {
        emit MageChanged(_mage, mage_);
        _mage = mage_;
    }
}