// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// @author 0xQruz
contract Nrae is ERC20 {
    constructor(uint256 initialSupply) ERC20('Nrae', 'ERN') {
        _mint(msg.sender, initialSupply);
    }
}