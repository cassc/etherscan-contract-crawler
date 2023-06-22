// TELEGRAM: https://t.me/PerpyExchange
// WEBSITE: https://www.perpy.exchange
// TWITTER: https://twitter.com/PerpyExchange

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract PERPY is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Perpy", "PERPY", 18, 0x691aC5FF81ff80f38881Af24586811e2dC7231b8, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 609338108;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}