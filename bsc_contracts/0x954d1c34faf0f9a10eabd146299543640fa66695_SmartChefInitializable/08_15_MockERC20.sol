// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
        _decimals = decimals_;
    }

    function mintTokens(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}