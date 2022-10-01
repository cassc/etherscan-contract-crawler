// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract NatoInu is ERC20, Ownable {
    constructor(address to_) ERC20("NATO Inu", "$NATO") {
        _mint(to_, 100000000000 * 10 ** decimals());
    }
}