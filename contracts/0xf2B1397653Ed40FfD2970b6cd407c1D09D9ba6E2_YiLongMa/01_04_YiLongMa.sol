// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * Website: https://yilongma-erc.com
 * Telegram: https://t.me/yilongmaercportal
 * Twitter: https://twitter.com/YiLongMaERC
 */

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {IUniswapV2Factory, IUniswapV2Router} from "./interfaces/Uniswap.sol";

contract YiLongMa is Owned, ERC20 {
    uint8 internal _decimals = 9;
    uint256 internal _totalSupply = 1000000 * 10 ** _decimals;

    uint256 public _maxTxAmount = (_totalSupply * 2) / 100;
    uint256 public _maxWalletAmount = _maxTxAmount;
    uint256 public _buyTax = 30;
    uint256 public _sellTax = 30;

    uint256 internal swapThreshold = _maxWalletAmount;
    IUniswapV2Router internal uniswapV2Router;
    address internal WETH;
    address internal uniswapV2Pair;
    address internal marketingWallet;
    mapping(address => bool) internal excludedFromLimits;
    uint256 internal launchedBlock;
    bool internal tradingEnabled;
    bool internal internalSwap;

    modifier lockInternalSwap() {
        internalSwap = true;
        _;
        internalSwap = false;
    }

    constructor() Owned(msg.sender) ERC20(unicode"YiLongMa", unicode"一龙马", _decimals) {
        super._mint(address(this), _totalSupply);
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        marketingWallet = msg.sender;
        excludedFromLimits[msg.sender] = true;
        excludedFromLimits[address(this)] = true;
    }

    function removeLimits() external onlyOwner {
        uint256 maxAmount = _totalSupply;
        _maxTxAmount = maxAmount;
        _maxWalletAmount = maxAmount;
    }

    function removeTaxes() external onlyOwner {
        _buyTax = 0;
        _sellTax = 0;
    }

    function enableTrading(uint256 db) external payable onlyOwner {
        require(!tradingEnabled, "Trading Already Enabled");
        WETH = uniswapV2Router.WETH();
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
        address currentPair = uniswapV2Factory.getPair(address(this), WETH);
        if (currentPair == address(0)) currentPair = uniswapV2Factory.createPair(address(this), WETH);
        uniswapV2Pair = currentPair;
        uint256 initialDb = _buyTax;
        _buyTax = db;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), balanceOf[address(this)], 0, 0, owner, block.timestamp);
        launchedBlock = block.number;
        tradingEnabled = true;
        _buyTax = initialDb;
    }

    function renounceOwnership() external onlyOwner {
        uint256 maxAmount = _totalSupply;
        require(_maxTxAmount == maxAmount && _maxWalletAmount == maxAmount, "Limits Not Yet Removed");
        require(_buyTax == 0 && _sellTax == 0, "Taxes Not Yet Removed");
        require(tradingEnabled, "Trading Not Yet Enabled");
        Owned.transferOwnership(address(0));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return _tokenTransfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        return _tokenTransfer(from, to, amount);
    }

    function _tokenTransfer(address from, address to, uint256 amount) internal returns (bool) {
        if (!excludedFromLimits[from]) require(tradingEnabled, "Trading Not Yet Enabled");
        require(from != address(0) && to != address(0), "Transfer From/To Zero Address");
        require(amount > 0, "Transfer Amount Zero");

        uint256 taxAmount = 0;
        if (from != owner && to != owner) {
            taxAmount = !internalSwap ? (amount * (block.number <= launchedBlock ? 99 : _buyTax)) / 100 : 0;
            if (from == uniswapV2Pair && !excludedFromLimits[to]) {
                require(amount <= _maxTxAmount, "Exceeds Max TX");
                require(balanceOf[to] + amount <= _maxWalletAmount, "Exceeds Max Wallet");
            } else if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = (amount * _sellTax) / 100;
                if (!internalSwap) _internalSwap(amount);
            }
        }

        balanceOf[from] -= amount;

        if (taxAmount > 0) {
            balanceOf[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        uint256 finalAmount = amount - taxAmount;
        balanceOf[to] += finalAmount;
        emit Transfer(from, to, finalAmount);

        return true;
    }

    function _internalSwap(uint256 amount) internal lockInternalSwap {
        uint256 swapAmount = _min(amount, _min(balanceOf[address(this)], swapThreshold));
        if (swapAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapAmount, 0, path, marketingWallet, block.timestamp);
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = (a > b) ? b : a;
    }
}