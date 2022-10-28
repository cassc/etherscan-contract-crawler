// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./interfaces/ITreasuryHelper.sol";


contract VaultOwned is Ownable {
    address internal _vault;

    function setVault(address vault_) external onlyOwner() returns (bool) {
        _vault = vault_;

        return true;
    }

    function vault() public view returns (address) {
        return _vault;
    }

    modifier onlyVault() {
        require(_vault == msg.sender, "VaultOwned: caller is not the Vault");
        _;
    }
}

contract PSI is ERC20, VaultOwned {
    uint256 private constant PERCENT_DENOMENATOR = 1000;
    address private constant DEAD = address(0xdead);
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    uint64 public deadblocks = 5;
    address private _marketingWallet;

    mapping(address => bool) private _isTaxExcluded;
    mapping(address => bool) private _isLimitless;

    uint256 public taxTreasury = (PERCENT_DENOMENATOR * 5) / 100;
    uint256 public taxDev = (PERCENT_DENOMENATOR * 0) / 100;
    uint256 public additionalSellTax = (PERCENT_DENOMENATOR * 0) / 100;

    uint256 public maxTx = (PERCENT_DENOMENATOR * 100) / 100;

    uint256 public maxSellTx = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public maxWallet = (PERCENT_DENOMENATOR * 100) / 100;
    bool public enableLimits = true;

    uint256 private _totalTax;
    bool private _taxesOff;

    uint256 private _liquifyRate = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public launchTime;
    uint256 private _launchBlock;
    bool  private _tradingActive;

    IUniswapV2Router02 public uniswapV2Router;
    ITreasuryHelper treasuryHelper;

    address public uniswapV2Pair;

    mapping(address => bool) private _isBot;

    bool private _swapEnabled = true;
    bool private _swapping = false;

    modifier swapLock() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() ERC20('PSI Protocol', 'PSI')  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            DAI
        );
        _marketingWallet = owner();
        uniswapV2Router = _uniswapV2Router;
        _setTotalTax();
        _isTaxExcluded[address(this)] = true;
        _isTaxExcluded[msg.sender] = true;
        _isLimitless[address(this)] = true;
        _isLimitless[msg.sender] = true;
        deadblocks = 0;

        _approve(owner(), address(uniswapV2Router), type(uint256).max);
        ERC20(DAI).approve(address(uniswapV2Router), type(uint256).max);
        ERC20(DAI).approve(address(this), type(uint256).max);
        ERC20(DAI).approve(address(treasuryHelper), type(uint256).max);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        uint256 contractTokenBalance = balanceOf(address(this));

        bool _isBuy = sender == uniswapV2Pair && recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;

        if (_isSwap && enableLimits) {
            bool _skipCheck = _isLimitless[recipient] || _isLimitless[sender];
            require(_tradingActive || _skipCheck, "Trading is not active.");

            uint256 _maxTx = totalSupply() * maxTx / PERCENT_DENOMENATOR;
            require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
            if (_isBuy) {
                uint256 _maxWallet = totalSupply() * maxWallet / PERCENT_DENOMENATOR;
                require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
            } else {
                uint256 _maxSellTx = totalSupply() * maxSellTx / PERCENT_DENOMENATOR;
                require(_maxSellTx >= amount || _skipCheck, "Sell tx amount exceed limit");
            }
        }
        if (_isBuy) {
            if (block.number < _launchBlock + deadblocks) {
                _isBot[recipient] = true;
            }
        } else {
            require(!_isBot[recipient], 'Stop botting!');
            require(!_isBot[sender], 'Stop botting!');
            require(!_isBot[_msgSender()], 'Stop botting!');
        }

        uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) / PERCENT_DENOMENATOR;
        bool _overMin = contractTokenBalance >= _minSwap;

        if (_swapEnabled && !_swapping && !_isOwner && _overMin && launchTime != 0 && _isSell) {
            _swap(_minSwap, _isSell);
        }

        uint256 tax = 0;
        if (launchTime != 0 && _isSwap && !_taxesOff && !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])) {
            tax = (amount * getTotalTax(_isSell)) / PERCENT_DENOMENATOR;
            if (tax > 0) {
                super._transfer(sender, address(this), tax);
            }
        }
        super._transfer(sender, recipient, amount - tax);
    }

    function enableTrading() public onlyOwner {
        _tradingActive = true;
        deadblocks = 0;
        launchTime = block.timestamp;
        _launchBlock = block.number;
    }

    function _swap(uint256 _amountToSwap, bool isSell) private swapLock {
        uint256 treasuryTokens = (_amountToSwap * taxTreasury) / getTotalTax(isSell);
        if (treasuryTokens > 0) {
            swapTokensForDai(treasuryTokens, address(treasuryHelper));
            treasuryHelper.depositTreasury();
        }

        uint256 marketingTokens = _amountToSwap - treasuryTokens;
        if (marketingTokens > 0) {
            swapTokensForDai(marketingTokens, _marketingWallet);
        }
    }

    function mint(address account, uint256 amount) external onlyVault() {
        _mint(account, amount);
    }

    function swapTokensForDai(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DAI;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    receive() external payable {}

    function isBotBlacklisted(address account) external view returns (bool) {
        return _isBot[account];
    }

    function blacklistBot(address account) external onlyOwner {
        require(account != address(uniswapV2Router), 'cannot blacklist router');
        require(account != uniswapV2Pair, 'cannot blacklist pair');
        require(!_isBot[account], 'user is already blacklisted');
        _isBot[account] = true;
    }

    function forgiveBot(address account) external onlyOwner {
        require(_isBot[account], 'user is not blacklisted');
        _isBot[account] = false;
    }

    function getTotalTax(bool isSell) private returns (uint256) {
        if (isSell) {
            return _totalTax + additionalSellTax;
        }
        return _totalTax;
    }

    function _setTotalTax() private {
        _totalTax = taxTreasury + taxDev;
        require(_totalTax <= (PERCENT_DENOMENATOR * 25) / 100, 'tax cannot be above 25%');
    }

    function setAdditionalSellTax(uint256 _tax) external onlyOwner {
        additionalSellTax = _tax;
        require(additionalSellTax <= (PERCENT_DENOMENATOR * 50) / 100, 'additionalSellTax cannot be above 50%');
    }

    function setTaxTreasury(uint256 _tax) external onlyOwner {
        taxTreasury = _tax;
        _setTotalTax();
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= 10, 'max wallet cannot be below 0.1%');
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 10, 'max tx cannot be below 0.1%');
        maxTx = _maxTx;
    }

    function setMaxSellTx(uint256 _maxSellTx) external onlyOwner {
        require(_maxSellTx >= 10, 'max sell tx cannot be below 0.1%');
        maxSellTx = _maxSellTx;
    }

    function setTaxBuyer(uint256 _tax) external onlyOwner {
        taxDev = _tax;
        _setTotalTax();
    }

    function setEnableLimits(bool _enable) external onlyOwner {
        enableLimits = _enable;
    }

    function setLiquifyRate(uint256 _rate) external onlyOwner {
        require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
        _liquifyRate = _rate;
    }

    function setIsTaxExcluded(address _wallet, bool _isExcluded) external onlyOwner {
        _isTaxExcluded[_wallet] = _isExcluded;
    }

    function setTaxesOff(bool _areOff) external onlyOwner {
        _taxesOff = _areOff;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled;
    }

    function setTreasuryHelperAddress(address _helperAddress) external onlyOwner() {
        treasuryHelper = ITreasuryHelper(_helperAddress);
    }

    function forceSwap() external onlyOwner {
        swapTokensForDai(balanceOf(address(this)), _marketingWallet);
    }

    function forceSend() external onlyOwner {
        uint256 balance = ERC20(DAI).balanceOf(address(this));
        _approve(address(this), address(uniswapV2Router), balance);
        ERC20(DAI).transfer(msg.sender, balance);
    }
}