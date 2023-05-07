// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeBob is Ownable, ERC20 {

    constructor() ERC20("PepeBob", "PEPEBOB") {
        _mint(msg.sender, 5_000_000_000_000 * 10**uint(decimals()));
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}