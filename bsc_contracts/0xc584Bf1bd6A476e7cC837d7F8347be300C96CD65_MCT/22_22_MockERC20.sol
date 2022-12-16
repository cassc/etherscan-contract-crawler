// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    function mintTokens(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }

    function mintTokensFor(address _address, uint256 _amount) external {
        _mint(_address, _amount);
    }
}