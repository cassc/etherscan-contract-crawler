// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract GaiaToken is ERC20Permit {
    constructor() ERC20Permit("GaiaToken") ERC20("GaiaToken", "GAIA") {
        _mint(msg.sender, 100000000e18);
    }
}