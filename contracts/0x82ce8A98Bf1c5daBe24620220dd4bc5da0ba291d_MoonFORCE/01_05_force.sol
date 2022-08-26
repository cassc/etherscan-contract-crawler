// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MoonFORCE is ERC20 {

    uint8 constant _decimals = 9;

    constructor() ERC20("MoonFORCE", "FORCE") {
        _mint(msg.sender, 4000000000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }
}