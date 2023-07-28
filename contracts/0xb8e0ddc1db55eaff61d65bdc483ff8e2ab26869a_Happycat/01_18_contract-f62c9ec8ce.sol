// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Happycat is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Happycat", "Hcat") ERC20Permit("Happycat") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }
}