// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Smart is ERC20 {
    uint256 private _totalSupply = 100000000 * (10 ** 18);

    constructor() ERC20("Smart Token", "SMART", 0x23E3299177B250b881D0FB4cd5298E41FAd80898, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

    uint256 public PER_SELL_TAX = 0;
    uint256 public PER_BUY_TAX = 0;
    
    uint256 public PER_MAX_WALLET = _totalSupply;
    uint256 public PER_MAX_BUY = _totalSupply;
}