// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("Token", "TKN") {
        _mint(msg.sender, initialSupply);
    }
}