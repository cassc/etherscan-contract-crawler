// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
Will be worth nothing.
Will be worth nothing.
Will be worth nothing.
Will be worth nothing.
Will be worth nothing.
           _                   
          | |                  
 __      _| |____      ___ __  
 \ \ /\ / / '_ \ \ /\ / / '_ \ 
  \ V  V /| |_) \ V  V /| | | |
   \_/\_/ |_.__/ \_/\_/ |_| |_|

https://t.me/willbeworthnothing

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract wbwnCoin is Ownable, ERC20 {
    bool public limited;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;
    uint8 public buyTax = 15;
    uint8 public sellTax = 15;
    address public uniswapV2Pair;
    address private feesWallet;

    constructor() ERC20("wbwn", "wbwn") {
        _mint(msg.sender, INITIAL_SUPPLY);
        feesWallet = msg.sender;
    }

    function setRule(bool _limited, address _uniswapV2Pair) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setFees(uint8 newBuy, uint8 newSell) external onlyOwner {
        buyTax = newBuy;
        sellTax = newSell;
    }

    function setFeesWallet(address wallet) external onlyOwner {
        feesWallet = wallet;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (limited) {
            if (from == uniswapV2Pair) {
                transferWithFees(from, to, amount, buyTax);
            } else if (to == uniswapV2Pair) {
                transferWithFees(from, to, amount, sellTax);
            } else {
            super._transfer(from, to, amount);
            }
        } else {
            super._transfer(from, to, amount);
        }
    }

    function transferWithFees(
        address from,
        address to,
        uint256 amount,
        uint8 percentage
    ) internal {
        uint256 tax = (amount * percentage) / 100;
        uint256 netAmount = amount - tax;
        super._transfer(from, to, netAmount);
        super._transfer(from, feesWallet, tax);
    }
}