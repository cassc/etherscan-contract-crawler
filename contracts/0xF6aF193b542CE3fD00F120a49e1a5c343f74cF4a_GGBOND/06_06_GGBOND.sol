// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";

contract GGBOND is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    address public taxCollector;
    address public uniswapV2Pair;
    uint256 public tradingStartTimeStamp;
    uint256 public constant startingTax = 8;
    uint256 public constant taxDuration = 3 minutes;
    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply, address _taxCollector) ERC20("GGBOND", "GGBOND") {
        _mint(msg.sender, _totalSupply);
        taxCollector = _taxCollector;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
        }
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        require(tradingStartTimeStamp == 0, "Can only set pair once.");
        uniswapV2Pair = _uniswapV2Pair;
        tradingStartTimeStamp = block.timestamp;
    }

    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) override internal virtual {
        if (block.timestamp <= tradingStartTimeStamp + taxDuration && (from == uniswapV2Pair || to == uniswapV2Pair)) {
            uint256 taxAmount = (amount * startingTax) / 100;
            uint256 remainingAmount = amount - taxAmount;
            super._transfer(from, to, remainingAmount);
            super._transfer(from, taxCollector, taxAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {      
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0) && from != address(0)) {
            require(from == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }
}