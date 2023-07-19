// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ANTIBOT is ERC20, ERC20Burnable, Ownable {
    address public uniswapV2Pair;
    uint256 public sellTax = 4;
    address public taxWallet;

    constructor(address _taxWallet) ERC20("ANTIBOT", "ANTIBOT") {
        _mint(msg.sender, 666000000000 * 10 ** decimals());
        taxWallet = _taxWallet;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        if (to == uniswapV2Pair) {
            uint256 taxAmount = amount * sellTax / 100;
            require(balanceOf(from) >= amount + taxAmount, "Insufficient Balance");

            // Transfer tax to the tax wallet
            _transfer(from, taxWallet, taxAmount);

            amount = amount - taxAmount;
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}