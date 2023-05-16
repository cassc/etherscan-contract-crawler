// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OpenMusk is ERC20 {
    constructor() ERC20("OpenMusk", "OPMSK") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}