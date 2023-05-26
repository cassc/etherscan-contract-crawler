// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";

contract NFTsAreDead is ERC20, ERC20Burnable, ERC20Permit, AccessControl {
    constructor() ERC20("NFTsAreDead", "NFTSDED") ERC20Permit("NFTsAreDead") {
        _mint(msg.sender, 69420000000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}