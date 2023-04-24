// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CoomerCoin is ERC20 {

    constructor() ERC20("CoomerCoin", "COOM") {
        _mint(msg.sender, 696969696969 * 10 ** decimals());
    }
}