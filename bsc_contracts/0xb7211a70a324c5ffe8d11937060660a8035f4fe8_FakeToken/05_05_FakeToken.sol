//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface IFakeToken is IERC20 {
    function publicMint(address who, uint256 amount) external;
}


contract FakeToken is IFakeToken, ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function publicMint(address who, uint256 amount) external override {
        _mint(who, amount);
    }
}