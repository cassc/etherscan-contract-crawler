// TELEGRAM: https://t.me/Baby_Yoda_portal
// WEBSITE: https://babyyodacrypto.com
// TWITTER: https://twitter.com/baby_yoda_coin

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract BYODA is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Baby Yoda", "BYODA", 18, 0xCB3feA82c064cFBCdE5503b142f45CE0809178E7, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }


    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply * 0 / 10000;
    uint256 public MAX_BUY = _totalSupply * 200 / 10000;

    function update(uint256 _BUY_TAX, uint256 _SELL_TAX, uint256 _MAX_WALLET, uint256 _MAX_BUY) external {
    MAX_WALLET = _MAX_WALLET;
    MAX_BUY = _MAX_BUY;
    }
}