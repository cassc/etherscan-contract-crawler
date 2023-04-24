// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { IUniswapV2Factory } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import { IUniswapV2Router02 } from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import { Constants } from './libs/Constants.sol';
import { AppStorage } from './libs/AppStorage.sol';

contract Cut is ERC20, Ownable {
    using SafeMath for uint256;

    constructor() ERC20(Constants.NAME, Constants.SYMBOL) {
        AppStorage.TokenStore storage tokenStore = AppStorage.getTokenStore();

        tokenStore.maxTransactionAmount = Constants.TOTAL_SUPPLY * 1e18;
        tokenStore.maxWalletAmount = Constants.TOTAL_SUPPLY * 1e18;
        tokenStore.swapTokensAtAmount = Constants.TOTAL_SUPPLY * 1e18 / 10_000;

        tokenStore.buyFee = 0;
        tokenStore.sellFee = 0;

        tokenStore.isLimitsInEffect = true;
        tokenStore.isTradingActive = false;
        tokenStore.isSwapEnabled = false;
        tokenStore.isLaunched = false;

        tokenStore.marketingWallet = address(msg.sender);

        tokenStore.uniswapV2Pair = IUniswapV2Factory(Constants.UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), Constants.UNISWAP_V2_ROUTER.WETH());

        // Exclude from paying feess or having max transaction amount
        setIsExcludedFromFees(owner(), true);
        setIsExcludedFromFees(address(this), true);
        setIsExcludedFromFees(address(0xdead), true);
        
        setIsExcludedFromMaxTransactionAmount(owner(), true);
        setIsExcludedFromMaxTransactionAmount(address(this), true);
        setIsExcludedFromMaxTransactionAmount(address(0xdead), true);
        setIsExcludedFromMaxTransactionAmount(address(Constants.UNISWAP_V2_ROUTER), true);
        setIsExcludedFromMaxTransactionAmount(tokenStore.uniswapV2Pair, true);
        
        setIsAMMPair(tokenStore.uniswapV2Pair, true);

        _mint(msg.sender, Constants.TOTAL_SUPPLY * 1e18);
    }

    function _transfer(address from, address to, uint256 amount)
        internal override
    {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        AppStorage.TokenStore storage tokenStore = AppStorage.getTokenStore();

        if (tokenStore.isLimitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !tokenStore.isSwapping
            ) {
                if (!tokenStore.isTradingActive) {
                    require(
                        tokenStore.isExcludedFromFee[from] || tokenStore.isExcludedFromFee[to],
                        'Trading is not active.'
                    );
                }

                // Buy
                if (
                    tokenStore.isAMMPairs[from] &&
                    !tokenStore.isExcludedFromMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= tokenStore.maxTransactionAmount,
                        'Buy transfer amount exceeds the maxTransactionAmount.'
                    );
                    require(
                        amount + balanceOf(to) <= tokenStore.maxWalletAmount,
                        'Max wallet amount exceeded'
                    );
                }
                // Sell
                else if (
                    !tokenStore.isExcludedFromMaxTransactionAmount[from] &&
                    tokenStore.isAMMPairs[to]
                ) {
                    require(
                        amount <= tokenStore.maxTransactionAmount,
                        'Sell transfer amount exceeds the maxTransactionAmount.'
                    );
                } else if (!tokenStore.isExcludedFromMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= tokenStore.maxWalletAmount,
                        'Max wallet amount exceeded.'
                    );
                }
            }
        }

        if (
            balanceOf(address(this)) >= tokenStore.swapTokensAtAmount &&
            tokenStore.isSwapEnabled &&
            !tokenStore.isSwapping &&
            !tokenStore.isAMMPairs[from] &&
            !tokenStore.isExcludedFromFee[from] &&
            !tokenStore.isExcludedFromFee[to]
        ) {
            tokenStore.isSwapping = true;

            _swapBack();

            tokenStore.isSwapping = false;
        }

        bool takeFee = !tokenStore.isSwapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (tokenStore.isExcludedFromFee[from] || tokenStore.isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 fee = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (tokenStore.isAMMPairs[to] && tokenStore.sellFee > 0) {
                fee = amount.mul(tokenStore.sellFee).div(10_000);
                tokenStore.feeAmount += fee;
            }
            // on buy
            else if (tokenStore.isAMMPairs[from] && tokenStore.buyFee > 0) {
                fee = amount.mul(tokenStore.buyFee).div(10_000);
                tokenStore.feeAmount += fee;
            }

            if (fee > 0) {
                super._transfer(from, address(this), fee);
            }

            amount -= fee;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount)
        private
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = Constants.UNISWAP_V2_ROUTER.WETH();

        _approve(address(this), address(Constants.UNISWAP_V2_ROUTER), tokenAmount);

        // make the swap
        Constants.UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function _swapBack() private {
        AppStorage.TokenStore storage tokenStore = AppStorage.getTokenStore();

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokenStore.feeAmount;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > tokenStore.swapTokensAtAmount * 20) {
            contractBalance = tokenStore.swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens

        uint256 amountToSwapForETH = contractBalance;

        _swapTokensForEth(amountToSwapForETH);

        tokenStore.feeAmount = 0;


        (success, ) = tokenStore.marketingWallet.call{
            value: address(this).balance
        }('');
    }

    function enableTrading(
        uint256 _buyFee,    // 9000
        uint256 _sellFee    // 9000
    ) external onlyOwner {
        AppStorage.TokenStore storage tokenStore = AppStorage.getTokenStore();

        tokenStore.buyFee = _buyFee;
        tokenStore.sellFee = _sellFee;
        
        tokenStore.isTradingActive = true;
        tokenStore.isSwapEnabled = true;
    }

    function fourTwenty(
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _maxTransactionAmount,
        uint256 _maxWalletAmount
    ) external onlyOwner {
        AppStorage.TokenStore storage tokenStore = AppStorage.getTokenStore();

        require(!tokenStore.isLaunched, 'Make memes great again');

        tokenStore.buyFee = _buyFee;
        tokenStore.sellFee = _sellFee;

        tokenStore.maxTransactionAmount = _maxTransactionAmount * 1e18;
        tokenStore.maxWalletAmount =  _maxWalletAmount * 1e18;

        tokenStore.isLaunched = true;
    }

    // Receive and send

    receive() external payable {}

    function manualSend() external {
        bool success;
        (success, ) = AppStorage.getTokenStore().marketingWallet.call{
            value: address(this).balance
        }('');
    }

    function manualSwap(uint256 amount) external {
        require(amount <= balanceOf(address(this)) && amount > 0, 'Wrong amount');
        _swapTokensForEth(amount);
    }

    // Management functions

    function getFeeAmount() public view returns (uint256) {
        return AppStorage.getTokenStore().feeAmount;
    }

    function setIsExcludedFromFees(address _address, bool _isExcluded) public onlyOwner {
        AppStorage.getTokenStore().isExcludedFromFee[_address] = _isExcluded;
    }

    function batchSetIsExcludedFromFees(address[] calldata _addresses, bool _isExcluded) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            AppStorage.getTokenStore().isExcludedFromFee[_addresses[i]] = _isExcluded;
        }
    }

    function setIsExcludedFromMaxTransactionAmount(address _address, bool _isExcluded) public onlyOwner {
        AppStorage.getTokenStore().isExcludedFromMaxTransactionAmount[_address] = _isExcluded;
    }

    function batchSetIsExcludedFromMaxTransactionAmount(address[] calldata _addresses, bool _isExcluded) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            AppStorage.getTokenStore().isExcludedFromMaxTransactionAmount[_addresses[i]] = _isExcluded;
        }
    }

    function setBuyFee(uint256 _buyFee) public onlyOwner {
        AppStorage.getTokenStore().buyFee = _buyFee;
    }

    function setSellFee(uint256 _sellFee) public onlyOwner {
        AppStorage.getTokenStore().sellFee = _sellFee;
    }

    function setIsTradingActive(bool _isTradingActive) public onlyOwner {
        AppStorage.getTokenStore().isTradingActive = _isTradingActive;
    }

    function setIsSwapEnabled(bool _isSwapEnabled) public onlyOwner {
        AppStorage.getTokenStore().isSwapEnabled = _isSwapEnabled;
    }

    function setIsLimitsInEffect(bool _isLimitsInEffect) public onlyOwner {
        AppStorage.getTokenStore().isLimitsInEffect = _isLimitsInEffect;
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) public onlyOwner {
        AppStorage.getTokenStore().swapTokensAtAmount = _swapTokensAtAmount;
    }

    function setMaxTransactionAmount(uint256 _maxTransactionAmount) public onlyOwner {
        AppStorage.getTokenStore().maxTransactionAmount = _maxTransactionAmount;
    }

    function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        AppStorage.getTokenStore().maxWalletAmount = _maxWalletAmount;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        AppStorage.getTokenStore().marketingWallet = _marketingWallet;
    }

    function getMarketingWallet() public view returns (address) {
        return AppStorage.getTokenStore().marketingWallet;
    }

    function setIsLaunched(bool _isLaunched) public onlyOwner {
        AppStorage.getTokenStore().isLaunched = _isLaunched;
    }

    function setIsAMMPair(address _address, bool _isAMMPair) public onlyOwner {
        AppStorage.getTokenStore().isAMMPairs[_address] = _isAMMPair;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) public onlyOwner {
        AppStorage.TokenStore storage tokenStore = AppStorage.getTokenStore();

        setIsAMMPair(tokenStore.uniswapV2Pair, false);
        tokenStore.uniswapV2Pair = _uniswapV2Pair;
        setIsAMMPair(tokenStore.uniswapV2Pair, true);
    }

    function getUniswapV2Pair() public view returns (address) {
        return AppStorage.getTokenStore().uniswapV2Pair;
    }
}