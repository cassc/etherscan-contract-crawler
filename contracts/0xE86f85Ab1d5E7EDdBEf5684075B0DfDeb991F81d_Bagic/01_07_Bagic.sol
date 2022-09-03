// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bagic is ERC20Burnable, Ownable {
    constructor() ERC20("Bagic", "BAGIC") {}

    mapping(address => bool) isController;

    function setController(address address_, bool bool_) external onlyOwner {
        isController[address_] = bool_;
    }

    modifier onlyControllers() {
        require(isController[msg.sender], "You are not authorized!");
        _;
    }

    function mint(address to_, uint256 amount_) external onlyControllers {
        _mint(to_, amount_);
    }

    function burn(address from_, uint256 amount_) external onlyControllers {
        _burn(from_, amount_);
    }
}