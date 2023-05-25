// SPDX-License-Identifier: MIT
/*

    ____   __    _  _  ____    __   
    (  _ \ /__\  ( \( )(  _ \  /__\  
    )___//(__)\  )  (  )(_) )/(__)\ 
    (__) (__)(__)(_)\_)(____/(__)(__)

    Website: https://gopandaproj.com
    Telegram: https://t.me/pandacoinchannel
    Twitter: https://twitter.com/GoPandaProj

    * Liquidity Locked
    * Ownership Locked

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PANDA is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;
    uint256 constant tokens = 100_000_000_069 * 1e18;

    constructor() ERC20("PANDA", "PANDA") {
        _mint(msg.sender, tokens);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function setValues(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}