// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HAY is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) public controllers;

    constructor() ERC20("HAY", "HAY") {
        _mint(msg.sender, 9 * 10**decimals());
    }

    function mint(address to, uint256 amount) public {
        require(controllers[msg.sender], "Only controllers can mint");

        _mint(to, amount);
    }

    function addController(address controller) public onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) public onlyOwner {
        controllers[controller] = false;
    }
}