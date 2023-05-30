// contracts/MCHINAToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MCHINAToken is ERC20 {
    constructor() ERC20("Machina", "MCHINA") {
        uint256 initialSupply = 50000000000000000;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}