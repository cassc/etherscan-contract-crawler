// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

import "hardhat/console.sol";

//     ERC20BurnableUpgradeable
contract RAISER is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20CappedUpgradeable, ERC20BurnableUpgradeable {
    function initialize(string memory _name, string memory _symbol, uint256 _cap) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ERC20Capped_init(_cap);
        __ERC20Burnable_init();        
    }

    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._mint(to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}