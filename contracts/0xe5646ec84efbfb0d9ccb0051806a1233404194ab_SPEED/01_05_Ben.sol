// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SPEED is ERC20 {
    uint256 private _totalSupply = 100000000 * (10 ** 18);

    constructor() ERC20("ben Token", "BEN", 0xA90083263614aB95Bf6e89eb94f3a036A1191F4B, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

    address public takeFee;
    bool public inswap = true;
}