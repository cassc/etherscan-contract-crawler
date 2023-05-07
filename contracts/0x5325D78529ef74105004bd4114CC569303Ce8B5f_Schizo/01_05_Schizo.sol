// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Schizo is ERC20 {
    constructor() ERC20("SCHIZO", "SCHIZO") {
        uint256 initialSupply = 694_200_000_000 * (10 ** 18);
        _mint(msg.sender, initialSupply);
    }
}