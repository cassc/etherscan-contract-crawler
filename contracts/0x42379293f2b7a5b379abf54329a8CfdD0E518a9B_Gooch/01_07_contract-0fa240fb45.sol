// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Gooch is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Gooch", "GCH") {
        _mint(msg.sender, 69420000000 * 10 ** decimals());
    }
}