// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VeryChineseCoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("Very Chinese Coin", "VCC") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
}