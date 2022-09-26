// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract PelosiCoin is ERC20, Ownable {
    constructor(address to_) ERC20("Pelosi Coin", "NANCY") {
        _mint(to_, 420000000 * 10 ** decimals());
    }
}