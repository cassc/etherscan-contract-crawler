// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MASK is Ownable, ERC20 {

    constructor() ERC20("MemeMask", "MASK") {
        _mint(msg.sender, 1_000_000_000_000 * 10**uint(decimals()));
    }
}