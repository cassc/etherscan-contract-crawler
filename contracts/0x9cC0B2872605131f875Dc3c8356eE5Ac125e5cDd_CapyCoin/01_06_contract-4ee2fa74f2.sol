// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract CapyCoin is ERC20, ERC20Burnable {
    constructor() ERC20("CapyCoin", "CAPY") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}