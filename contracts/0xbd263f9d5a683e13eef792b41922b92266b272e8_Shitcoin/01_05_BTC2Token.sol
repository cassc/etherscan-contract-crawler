// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Shitcoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("Shitcoin 2.0", "SHIT2.0") {
        _mint(msg.sender, initialSupply);
    }
    function decimals() override public view returns (uint8) {
        return 8;
    }
}