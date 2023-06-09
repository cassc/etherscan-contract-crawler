// SPDX-License-Identifier: Unlicensed
//http://t.me/SznPortal

pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';


contract Seazon is ERC20, Ownable {

    // uniswap
    IUniswapV2Router02 public uniRouter;
    address public uniPair;

    address private projectWallet;
    address private buyBackWallet;
    address private lpWallet;

    // taxes
    bool private taxesOff;
    uint256 public taxBuy = 8;
    uint256 public taxLPool = 1;
    uint256 public taxSell = 18;
    uint256 public taxBuyBack = 1;

    // limis
    bool public limitsOn = true;
    uint256 public maxWalletInPercent = 10;
    uint256 public maxTxInPercent = 5;
    mapping(address => bool) private isLimitFree;
    mapping(address => bool) private isTaxFree;

    // auto-liq
    uint256 private lpRate = 15;
    bool private swapOn = true;
    bool private swappingInProgress = false;

    modifier swapLock() {
        swappingInProgress = true;
        _;
        swappingInProgress = false;
    }

    constructor(address _projectWallet) ERC20('Seazon', 'SZN')  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniRouter = _uniswapV2Router;
        projectWallet = _projectWallet;
        buyBackWallet = owner();
        lpWallet = owner();
        isTaxFree[address(this)] = true;
        isTaxFree[msg.sender] = true;
        isLimitFree[address(this)] = true;
        isLimitFree[msg.sender] = true;
        _mint(owner(), 1_000_000_000 * 10 ** 18);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        checkLimits(sender, recipient, amount);
        swapTokens(sender, recipient, amount);
        transferTokens(sender, recipient, amount);
    }

    function transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool isBuy = sender == uniPair && recipient != address(uniRouter);
        bool isSell = recipient == uniPair;
        bool isSwap = isBuy || isSell;

        uint256 tax = 0;
        if (isSwap && !taxesOff && !(isTaxFree[sender] || isTaxFree[recipient])) {
            tax = (amount * sumTax(isSell)) / 100;
            if (tax > 0) {
                super._transfer(sender, address(this), tax);
            }
        }
        super._transfer(sender, recipient, amount - tax);
    }

    function checkLimits(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool isBuy = sender == uniPair && recipient != address(uniRouter);
        bool isSell = recipient == uniPair;
        bool isSwap = isBuy || isSell;


        if (limitsOn) {
            bool skipCheck = isLimitFree[recipient] || isLimitFree[sender];
            uint256 maxWallet = totalSupply() * maxWalletInPercent / 1000;
            if (isSwap) {
                uint256 maxTx = totalSupply() * maxTxInPercent / 1000;
                require(maxTx >= amount || skipCheck, "Max Tx Error");
                if (isBuy) {
                    require(maxWallet >= balanceOf(recipient) + amount || skipCheck, "Max Wallet Error");
                }
            }
        }
    }


    function swapTokens(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool isSell = recipient == uniPair;

        uint256 minSwap = (balanceOf(uniPair) * lpRate) / 10000;
        uint256 balance = balanceOf(address(this));
        bool overMin = balance >= minSwap;

        bool isOwner = sender == owner() || recipient == owner();
        if (swapOn && !swappingInProgress && !isOwner && overMin && isSell) {
            swap(minSwap);
        }
    }

    function swap(uint256 amount) private swapLock {
        uint256 balBefore = address(this).balance;
        uint256 lpTokens = (amount * taxLPool) / sumTax(true) / 2;

        uint256 tokensToSwap = amount - lpTokens;

        swapTokens(tokensToSwap);

        uint256 balance = address(this).balance - balBefore;
        if (balance > 0) {
            transferFees(balance, lpTokens);
        }
    }

    function swapTokens(uint256 tokensToSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();

        _approve(address(this), address(uniRouter), tokensToSwap);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}

    function transferFees(uint256 amountETH, uint256 amountLpTokens) private {
        uint256 lpETH = (amountETH * taxLPool) / sumTax(true);
        uint256 buyBackETH = (amountETH * taxBuyBack) / sumTax(true);

        if (amountLpTokens > 0) {
            addLp(amountLpTokens, lpETH);
        }
        payable(buyBackWallet).transfer(buyBackETH);
        payable(projectWallet).transfer(address(this).balance);
    }

    function addLp(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpWallet,
            block.timestamp
        );
    }

    function sumTax(bool isSell) private returns (uint256) {
        if (isSell) {
            return taxLPool + taxSell + taxBuyBack;
        } else {
            return taxLPool + taxBuy + taxBuyBack;
        }
    }

    function setTaxLPool(uint256 _taxLPool) external onlyOwner {
        taxLPool = _taxLPool;
    }

    function setMaxWalletInPercent(uint256 _maxWalletInPercent) external onlyOwner {
        maxWalletInPercent = _maxWalletInPercent;
    }

    function setMaxTxInPercent(uint256 _maxTxInPercent) external onlyOwner {
        maxTxInPercent = _maxTxInPercent;
    }

    function setLimitsOn(bool _limitsOn) external onlyOwner {
        limitsOn = _limitsOn;
    }

    function setTaxBuy(uint256 _taxBuy) external onlyOwner {
        taxBuy = _taxBuy;
        require(taxBuy <= 10, 'Buy Tax cannot be above 10%');
    }

    function setTaxSell(uint256 _taxSell) external onlyOwner {
        taxSell = _taxSell;
        require(taxSell <= 10, 'Sell Tax cannot be above 10%');
    }

    function setTaxBuyBack(uint256 _tax) external onlyOwner {
        taxBuyBack = _tax;
        require(taxSell <= 10, 'Buyback Tax cannot be above 10%');
    }
    
    function setLpRate(uint256 _lpRate) external onlyOwner {
        lpRate = _lpRate;
    }

    function setIsTaxFree(address _wallet, bool val) external onlyOwner {
        isTaxFree[_wallet] = val;
    }

    function setSwapOn(bool _swapOn) external onlyOwner {
        swapOn = _swapOn;
    }

    function setTaxesOff(bool _taxesOff) external onlyOwner {
        taxesOff = _taxesOff;
    }

    function setProjectWallet(address _projectWallet) external onlyOwner {
        projectWallet = _projectWallet;
    }

    function setBuyBackWallet(address _buyBackWallet) external onlyOwner {
        buyBackWallet = _buyBackWallet;
    }

    function setLpWallet(address _lpWallet) external onlyOwner {
        lpWallet = _lpWallet;
    }

    function forceSwapTokens() external swapLock onlyOwner {
        swapTokens(balanceOf(address(this)));
        (bool success,) = address(projectWallet).call{value : address(this).balance}("");
    }

    function forceSendEth() external onlyOwner {
        (bool success,) = address(projectWallet).call{value : address(this).balance}("");
    }
}