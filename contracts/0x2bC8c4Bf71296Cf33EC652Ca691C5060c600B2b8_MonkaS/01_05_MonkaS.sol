// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MonkaS is ERC20 {

    constructor() ERC20("MONKAS", "MONKAS") {
        _mint(msg.sender, 420000000000 ether);
    }

}