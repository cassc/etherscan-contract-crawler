// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZeroEffortToken is ERC20 {
    constructor() ERC20("Zero Effort Token", "ZET") {
        _mint(msg.sender, 420000000000 * 10 ** decimals());
    }
}