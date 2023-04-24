// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

contract GaryGensler is ERC20, ERC20Burnable {
    constructor() ERC20("Gary Gensler", "GG") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}