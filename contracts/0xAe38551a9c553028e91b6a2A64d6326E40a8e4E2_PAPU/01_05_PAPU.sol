// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PAPU is ERC20 {
    constructor () ERC20("PAPU", "PAPU") {
        _mint(msg.sender, 69_000_000_000 ether);
    }
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}