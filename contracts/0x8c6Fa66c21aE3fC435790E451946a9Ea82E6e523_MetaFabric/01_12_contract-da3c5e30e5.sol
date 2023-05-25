// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MetaFabric is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("MetaFabric", "FABRIC") ERC20Permit("MetaFabric") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}