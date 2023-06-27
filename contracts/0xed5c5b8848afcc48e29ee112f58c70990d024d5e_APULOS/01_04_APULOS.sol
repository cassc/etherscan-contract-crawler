// TELEGRAM: https://t.me/apulosportal
// WEBSITE: https://www.apulos.finance/
// TWITTER: https://twitter.com/ApulosERC20

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract APULOS is Ownable, ERC20 {
    uint256 private _totalSupply = 15000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Apulos", "APULOS", 18, 0x1A3BFD89066A734A8A226610dCfcCae402D16Da6, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }


    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}