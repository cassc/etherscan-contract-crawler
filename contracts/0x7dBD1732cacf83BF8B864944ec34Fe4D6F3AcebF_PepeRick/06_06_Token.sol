// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeRick is Ownable, ERC20 {

    constructor() ERC20("Pepe Rick", "PEPERICK") {
        _mint(msg.sender, 8_888_888_888_888 * 10**uint(decimals()));
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}