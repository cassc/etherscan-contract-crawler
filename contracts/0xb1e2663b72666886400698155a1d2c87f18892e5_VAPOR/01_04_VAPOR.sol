// TELEGRAM: https://t.me/vapormixer
// WEBSITE: https://vapormixer.com
// TWITTER: https://twitter.com/VaporMixer

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract VAPOR is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("VaporMixer", "VAPOR", 18, 0xDcBeB0C74e3B412a7156187817a4DcEd7499eD64, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 91599684;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}