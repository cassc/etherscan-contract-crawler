// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OREOToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("OREO Token", "OREO") {
        _mint(msg.sender, initialSupply);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}