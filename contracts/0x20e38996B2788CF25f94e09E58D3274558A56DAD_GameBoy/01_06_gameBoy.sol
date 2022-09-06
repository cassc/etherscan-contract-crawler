//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GameBoy is ERC20 {
    constructor() ERC20("Game Boy", "GAMEBOY") {
        _mint(msg.sender, 1_000_000_000 * 10 ** 8);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}