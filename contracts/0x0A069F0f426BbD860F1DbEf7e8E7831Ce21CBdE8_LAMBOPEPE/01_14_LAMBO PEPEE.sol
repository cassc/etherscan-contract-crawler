// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract LAMBOPEPE is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("LAMBO PEPE", "$LPEPE") ERC20Permit("LAMBO PEPE") {
        _mint(msg.sender, 120000000000000 * 10 ** decimals());
    }
}