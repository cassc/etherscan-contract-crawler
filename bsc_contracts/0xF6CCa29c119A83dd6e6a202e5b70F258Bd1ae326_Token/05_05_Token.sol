// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20("ZROs", "ZROs") {
    constructor() {
        _mint(0xbB625390769470B667A91646b96780854b29a54e, 1000000000 * 10 ** decimals());
    }
}