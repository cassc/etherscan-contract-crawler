// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reddio20General is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 amount
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, amount * 1 ether);
    }
}