// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NoTickerToken is ERC20 {
    constructor() ERC20("No ticker", "NOTICKER") {
        _mint(msg.sender, 1000000000000 * 10**8);
    }
    function decimals() override public pure returns (uint8) {
        return 8;
    }
}