// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CAT is ERC20, ERC20Burnable, Ownable {

    bool public limited;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklisted;

    constructor(string memory _name, string memory _symbol, uint256 totalSupply) 

    ERC20(_name, _symbol) {
      _mint(msg.sender, totalSupply * 10 ** decimals());
    }

    function blockBot(address _address) external onlyOwner {
        blacklisted[_address] = true;
    }
    
    function unblock(address account) external onlyOwner {
        blacklisted[account] = false;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount) external onlyOwner {
      limited = _limited;
      uniswapV2Pair = _uniswapV2Pair;
      maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklisted[to] && !blacklisted[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading not started");
            return;
        }

        if (limited && to != uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= (maxHoldingAmount * 10 ** decimals()), "Exceeds max holding amount");
        }
    }

}