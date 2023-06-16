// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract OxMilady is Ownable, ERC20 {
    uint256 private _totalSupply = 25000000 * (10 ** 18);

    constructor() ERC20("0xMilady", "0xLADY", 18, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }
}