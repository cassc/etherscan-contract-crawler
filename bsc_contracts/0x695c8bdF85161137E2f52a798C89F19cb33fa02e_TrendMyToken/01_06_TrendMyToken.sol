// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";

contract TrendMyToken is ERC20, Ownable {
    constructor(address to_) ERC20("Trend My Token", "$TREND") {
        _mint(to_, 1000000000 * 10 ** decimals());
    }
}