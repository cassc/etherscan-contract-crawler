// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract ZoomerPepeFumoCR70Inu is ERC20, Ownable {
    constructor() ERC20("ZoomerPepeFumoCR7.0Inu", "WGGBOND") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
}