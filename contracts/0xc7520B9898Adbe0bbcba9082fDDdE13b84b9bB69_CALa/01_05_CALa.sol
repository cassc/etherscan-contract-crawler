// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CALa is ERC20 {
    constructor() ERC20("CALa", "Calcium Again") {
        uint256 tokenSupply = 420690000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}