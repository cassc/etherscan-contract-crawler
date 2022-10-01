// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LAVG is ERC20 {
    constructor() ERC20("LAVG", "LAVG") {
        _mint(msg.sender, 299000000 * 10**decimals());
    }
}