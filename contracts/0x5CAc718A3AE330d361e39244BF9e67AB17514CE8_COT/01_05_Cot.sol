//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract COT is ERC20 {
    constructor() ERC20("CosplayToken", "COT") {
        _mint(msg.sender, 1_000_000_000 * (10 ** uint256(decimals())));
    }
}