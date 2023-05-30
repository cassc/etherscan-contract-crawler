// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SNACK is ERC20, Ownable {
    mapping(address => bool) controllers;

    constructor(uint256 initialSupply) ERC20("SNACK", "SNAC") {
        _mint(msg.sender, initialSupply * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "SNACK: Only controller can mint!");
        _mint(to, amount * 10 ** 18);
    }

    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "SNACK: Only controller can burn!");
        _burn(from, amount * 10 ** 18);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}