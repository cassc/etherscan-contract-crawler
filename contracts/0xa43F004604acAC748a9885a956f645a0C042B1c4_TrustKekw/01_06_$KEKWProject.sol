// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TrustKekw
 * @author https://twitter.com/kekwcoinlol
 * @author https://t.me/+1GR0HyRjeQwxZDZh 
 * @author https://kekwcoinlol.com
 */
contract TrustKekw is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    uint256 public taxPercentage = 5;
    address public marketingAddress =
        0xFDE3258547ff6F42eD995EeeDC21871b4Cdd2Af9;

    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply) ERC20("TrustKekw", "KEKW") {
        _mint(msg.sender, _totalSupply);
    }

    function setTax(uint _tax) external onlyOwner {
        require(_tax <= 5);
        taxPercentage = _tax;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _calculateTax(uint256 amount) internal view returns (uint, uint) {
        uint tax = (amount * taxPercentage) / 100;
        uint net = amount - tax;
        return (net, tax);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from != address(this) && to == uniswapV2Pair) {
            (uint net, uint tax) = _calculateTax(amount);
            // Transfer tax
            _transfer(from, marketingAddress, tax);

            super.transferFrom(from, to, net);
        } else {
            super.transferFrom(from, to, amount);
        }

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() || to == owner(),
                "Trading has not started"
            );
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount &&
                    super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbidden"
            );
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}