// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Connection is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("Connection", "CNT") ERC20Permit("Connection") {
        _mint(msg.sender, 20000000000 * 10 ** decimals());
    }
}