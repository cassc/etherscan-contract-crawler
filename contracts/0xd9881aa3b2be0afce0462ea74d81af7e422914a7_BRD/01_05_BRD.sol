// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BRD is ERC20 {
    constructor() ERC20("BRD", "BRD") {
        _mint(_msgSender(), 1000000000 * (10 ** decimals()));
    }
}