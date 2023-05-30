// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract NebulaNectar is ERC20 {
    constructor() ERC20("NebulaNectar", "NNECT") {
        _mint(msg.sender, 7071067811865476 * 10 ** decimals());
    }
}