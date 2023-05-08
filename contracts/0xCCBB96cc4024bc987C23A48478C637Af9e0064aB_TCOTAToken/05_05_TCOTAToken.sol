// contracts/TCOTAToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TCOTAToken is ERC20 {
    constructor() ERC20("Terracota", "TCOTA") {
        uint256 initialSupply = 10000000000000000;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}