// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        address addr,
        uint256 amount,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(addr, amount);
    }
}