// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Moon is ERC20 {
    constructor() ERC20("Moon", "MOON") {
        _mint(msg.sender, 210000000 * (10 ** 18));
    }
}