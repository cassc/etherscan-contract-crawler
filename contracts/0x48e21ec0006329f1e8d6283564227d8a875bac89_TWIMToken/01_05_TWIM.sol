// contracts/TWIMToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TWIMToken is ERC20 {
    function decimals() public view virtual override returns (uint8) {
    return 10;
    }
    constructor() ERC20("TWIM", "TWIM") {
        _mint(msg.sender, 100_000_000_000_000 * 10**decimals());
    }
}