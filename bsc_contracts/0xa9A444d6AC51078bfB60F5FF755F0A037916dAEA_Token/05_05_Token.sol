// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20("ZROs", "ZROs") {
    constructor() {
        _mint(0xe3747fda85A771738Ad9D55DF7D522374EE13bb1, 1000000000 * 10 ** decimals());
    }
}