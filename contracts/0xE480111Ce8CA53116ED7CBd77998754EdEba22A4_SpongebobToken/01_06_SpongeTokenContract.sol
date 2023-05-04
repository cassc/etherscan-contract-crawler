// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SpongebobToken is ERC20, Ownable {
    constructor() ERC20("Spongebob", "SPONGE") {
        _mint(0x85713b557F4c59a84239D8A3BfD7Aa1BF90eAC74, 40400000000 * 10 ** decimals());
        transferOwnership(0x85713b557F4c59a84239D8A3BfD7Aa1BF90eAC74);
    }
}