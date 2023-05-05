// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BobTheBuilder is Ownable, ERC20 {

    constructor() ERC20("Bob the Builder", unicode"BOBTB") {
        _mint(msg.sender, 3_647_777_777_777 * 10**uint(decimals()));
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}