//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HEHEToken is Ownable, ERC20 {
    bool public limited;
    bool public antiWhaled;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    uint256 public holdingBlockSlot;
    address public uniswapV2Pair;
    address public LPWallet;
    mapping(address => bool) public blacklists;
    mapping(address => uint) public antiWhale;

    constructor(uint256 _totalSupply) ERC20("PEPEBABY", "PEPEBABY") {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(address[] calldata _address, bool _isBlacklisting) external onlyOwner {
        uint256 len = _address.length;
        for (uint i = 0; i < len; i++) {
            if (!_isBlacklisting) {
                delete blacklists[_address[i]];
            } else
            {
                blacklists[_address[i]] = _isBlacklisting;
            }
        }

    }

    function setLPWallet(address _LPWallet) external onlyOwner {
        LPWallet = _LPWallet;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function setAntiWhale(bool _antiWhaled, uint256 _holdingBlockSlot) external onlyOwner {
        antiWhaled = _antiWhaled;
        holdingBlockSlot = _holdingBlockSlot;
    }

    function _afterTokenTransfer(address from, address to, uint256) override internal virtual {
        if (antiWhaled && from == uniswapV2Pair) {
            antiWhale[to] = block.number;
        }

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner() || from == LPWallet || to == LPWallet, "Trading is not started");
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbidden");
        }

        require((block.number - antiWhale[from]) > holdingBlockSlot, "Must be holding");
        if (antiWhaled && antiWhale[from] > 0) {
            delete antiWhale[from];
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}