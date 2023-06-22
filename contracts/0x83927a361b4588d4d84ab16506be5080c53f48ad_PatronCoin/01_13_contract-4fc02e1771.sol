// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";

contract PatronCoin is ERC20, ERC20Burnable, AccessControl {
    constructor() ERC20("Patron Coin", "PATRON") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}