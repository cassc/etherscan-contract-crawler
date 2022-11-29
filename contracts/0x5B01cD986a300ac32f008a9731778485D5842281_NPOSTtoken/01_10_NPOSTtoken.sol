// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract NPOSTtoken is
    ERC20PresetFixedSupplyUpgradeable,
    OwnableUpgradeable
{

////////////////////////////////////////// initialize

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) public virtual override initializer {
        __ERC20PresetFixedSupply_init(name, symbol, initialSupply, owner);
        _transferOwnership(owner);
    }


////////////////////////////////////////// write methods


    function mint(address account, uint256 amount)
        public
        onlyOwner
    {
        _mint(account, amount);
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }


    function burnFrom(address account, uint256 amount) public override {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}