// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";

contract Bloomberg is ERC20, Ownable {
    constructor(address to_) ERC20("Bloomberg", "Bloomberg") {
        _mint(to_, 50000000 * 10 ** decimals());
    }
}