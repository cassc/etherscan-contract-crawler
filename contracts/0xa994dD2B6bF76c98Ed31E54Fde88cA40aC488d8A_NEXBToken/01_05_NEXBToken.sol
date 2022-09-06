// contracts/NEXBToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract NEXBToken is ERC20 {
    function decimals() public view virtual override returns (uint8) {
    return 10;
    }
    constructor() ERC20("FinexBase", "NEXB") {
        _mint(msg.sender, 10_000_000_000 * 10**decimals());
    }
}