//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";



pragma solidity ^0.8.0;


contract MferCoin is Ownable, ERC20 {
    bool public limited;
    uint256 private constant TOTAL_SUPPLY = 69_420_420_000 ether;
    uint256 public maxHoldingAmount = TOTAL_SUPPLY * 2 / 100;
    uint256 public minHoldingAmount;
    address public uniswapV3Pair;
    mapping(address => bool) public blacklists;
    constructor() ERC20("Mfer Coin", "MFER") {
        _mint(msg.sender, TOTAL_SUPPLY);
        limited = true;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, address _uniswapV3Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV3Pair = _uniswapV3Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function setLimited(bool _limited) external onlyOwner {
        limited = _limited;
    }
    function setUniswapV3Pool(address _uniswapV3Pair) external onlyOwner {
        uniswapV3Pair = _uniswapV3Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        uint _balanceOfTo = balanceOf(to);
        address _owner = owner();
        if (uniswapV3Pair == address(0)) {
            require(from ==  _owner || to ==  _owner, "trading is not started");
            return;
        }

        if (limited && from == uniswapV3Pair) {
            require(_balanceOfTo + amount <= maxHoldingAmount && _balanceOfTo + amount >= minHoldingAmount, "Forbid");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}