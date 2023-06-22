// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ITZY is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000 * (10 ** 18);

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

    constructor() ERC20("ITZY", "IZY", 18) {
        _mint(msg.sender, _totalSupply);
    }
}