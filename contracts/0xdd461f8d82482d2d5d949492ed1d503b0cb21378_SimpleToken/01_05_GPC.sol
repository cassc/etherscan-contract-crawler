// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_,
        address gpcOwner
    ) ERC20(name, symbol) {
        uint256 reserve = (totalSupply_ * 25) / 100;
        _mint(msg.sender, (totalSupply_ - reserve));
        _mint(gpcOwner, reserve);
    }
}