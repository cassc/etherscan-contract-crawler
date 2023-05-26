// contracts/SmartERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SmartERC20 is ERC20 {

    constructor(address to, uint256 initSupply) ERC20("Smart game", "SMART") {
        _mint(to, initSupply);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

}