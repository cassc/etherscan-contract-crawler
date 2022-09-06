// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/IROOLAH.sol";

contract ROOLAH is IROOLAH, ERC20Upgradeable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet minters;

    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("Roolah", "ROOLAH");
    }

    function addMinter(address minter) external onlyOwner {
        require(minters.add(minter), "Minter already added");
    }

    function removeMinter(address minter) external onlyOwner {
        require(minters.remove(minter), "Minter not added");
    }

    function mint(address recipient, uint256 amount) external {
        require(minters.contains(msg.sender), "Only minter addresses can mint");
        _mint(recipient, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}