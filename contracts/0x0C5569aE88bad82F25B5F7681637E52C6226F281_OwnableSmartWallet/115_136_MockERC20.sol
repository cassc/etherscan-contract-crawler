pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialSupplyRecipient
    ) ERC20(_name, _symbol) {
        uint256 initialSupply = 125_000 * 10 ** 18;
        _mint(_initialSupplyRecipient, initialSupply);
    }
}