// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// silent secrets - zkmessage.net
contract ZKMessage is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("ZKMessage", "MESS") {
        _mint(msg.sender, 62000000 * 10 ** decimals());
    }
}