// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*

https://twitter.com/ReviveETH
https://t.me/ReviveETH
https://revivecoin.io

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReviveCoin is Ownable, ERC20 {
    bool public limited;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 public constant INITIAL_MAX_HOLD = INITIAL_SUPPLY / 10;
    uint8 public buyTax = 5;
    uint8 public sellTax = 30;
    address public uniswapV2Pair;
    address private feesWallet;

    constructor() ERC20("Revive", "REVIVE") {
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() ||
                    to == owner() ||
                    msg.sender == owner() ||
                    tx.origin == owner(),
                "Trading is not started"
            );
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= INITIAL_MAX_HOLD,
                "Forbidden"
            );
        }
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