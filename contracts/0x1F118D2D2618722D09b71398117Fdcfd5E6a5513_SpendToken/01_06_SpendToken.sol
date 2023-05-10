// SPDX-License-Identifier: MIT
/**
*   _____ _____  ______ _   _ _____    _______ ____  _  ________ _   _ 
*  / ____|  __ \|  ____| \ | |  __ \  |__   __/ __ \| |/ /  ____| \ | |
* | (___ | |__) | |__  |  \| | |  | |    | | | |  | | ' /| |__  |  \| |
*  \___ \|  ___/|  __| | . ` | |  | |    | | | |  | |  < |  __| | . ` |
*  ____) | |    | |____| |\  | |__| |    | | | |__| | . \| |____| |\  |
* |_____/|_|    |______|_| \_|_____/     |_|  \____/|_|\_\______|_| \_|
*                                                                      
* 
* *** Website: https://spendtoken.com
*                                                                       
*
**/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpendToken is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor() ERC20("Spend Token", "SPND") {
        _mint(msg.sender, 88000000000000 * 10 ** decimals());
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {

        //Blacklist Check
        require(!blacklists[to] && !blacklists[from], "You are Blacklisted");

        //Only allow Owner to transfer if no router set (liquidity pool) 
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading is not yet started");
            return;
        }

        //Anti Whale, Forbid the purchase of anymore 
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbidden");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}