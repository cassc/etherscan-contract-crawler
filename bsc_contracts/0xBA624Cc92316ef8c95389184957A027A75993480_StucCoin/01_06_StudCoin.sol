// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";

contract StucCoin is ERC20, Ownable {
    constructor() ERC20("Stud Coin", "STUD") {
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }
}