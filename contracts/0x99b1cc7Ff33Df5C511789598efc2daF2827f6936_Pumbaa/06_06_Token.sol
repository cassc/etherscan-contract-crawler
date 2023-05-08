// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pumbaa is Ownable, ERC20 {

    constructor() ERC20("Pumbaa", "PUMBAA") {
        _mint(msg.sender, 5_000_000_000_000 * 10**uint(decimals()));
    }
}