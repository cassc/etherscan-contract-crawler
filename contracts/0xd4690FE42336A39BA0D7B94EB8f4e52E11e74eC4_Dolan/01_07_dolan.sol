// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**

     88     8888888b.   .d88888b.  888             d8888 888b    888 
 .d88888b.  888  "Y88b d88P" "Y88b 888            d88888 8888b   888 
d88P 88"88b 888    888 888     888 888           d88P888 88888b  888 
Y88b.88     888    888 888     888 888          d88P 888 888Y88b 888 
 "Y88888b.  888    888 888     888 888         d88P  888 888 Y88b888 
     88"88b 888    888 888     888 888        d88P   888 888  Y88888 
Y88b 88.88P 888  .d88P Y88b. .d88P 888       d8888888888 888   Y8888 
 "Y88888P"  8888888P"   "Y88888P"  88888888 d88P     888 888    Y888 
     88             

Dolan.party
twitter.com/DolanERC20
t.me/DolanERCPortal
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*/

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "./interfaces.sol";

contract Dolan is ERC20, Ownable {
    // events
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool excluded);
    event ExcludeFromMaxTransaction(address indexed account, bool excluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    // errors
    error ERC20FromZero();
    error ERC20ToZero();
    error TradingNotActive();
    error BuyTransferExceedsMaxTransactionAmount();
    error BuyExceedsMaxWallet();
    error SellTransferExceedsMaxTransactionAmount();
    error MaxWallet();
    error FeeTooHigh();
    error SwapAmountTooLow();
    error SwapAmountTooHigh();

    // constants
    uint256 public constant MAX_SUPPLY = 69 * 1e7 ether;
    address constant DEV_WALLET = 0xCEC00F92B9023368cD4b0d4f08f583A0f5AA7307;
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;
    address private constant BURN_ADDRESS = address(0xdEaD);

    uint256 private constant INITIAL_MAX_TRANSACTION_AMOUNT = 138 * 1e5 ether; // 2% from total supply maxTransactionAmountTxn
    uint256 private constant INITIAL_MAX_WALLET = 138 * 1e5 ether; // 2% from total supply maxWallet

    uint256 private constant INITIAL_BUY_LIQUIDITY_FEE = 2;
    uint256 private constant INITIAL_BUY_DEV_FEE = 2;

    uint256 private constant INITIAL_SELL_LIQUIDITY_FEE = 2;
    uint256 private constant INITIAL_SELL_DEV_FEE = 2;

    uint256 private constant MAX_TOTAL_FEE = 4;

    // states
    bool public tradingEnabled = false;
    bool public swapEnabled = false;
    bool public limitsEnabled = true;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;

    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;

    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;

    bool private isSwapping;

    // - exclude from fees and max transaction amount
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // - store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    //   could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // constructor
    constructor() ERC20("Dolan", unicode"DOLAN") {
        // create uniswap pair
        address _uniswapPair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;

        // initialize states
        maxTransactionAmount = INITIAL_MAX_TRANSACTION_AMOUNT;
        maxWallet = INITIAL_MAX_WALLET;
        swapTokensAtAmount = MAX_SUPPLY / 1000; // 0.1% swap wallet

        buyLiquidityFee = INITIAL_BUY_LIQUIDITY_FEE;
        buyDevFee = INITIAL_BUY_DEV_FEE;

        sellLiquidityFee = INITIAL_SELL_LIQUIDITY_FEE;
        sellDevFee = INITIAL_SELL_DEV_FEE;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(BURN_ADDRESS, true);

        excludeFromMaxTransaction(address(UNISWAP_V2_ROUTER), true);
        excludeFromMaxTransaction(address(_uniswapPair), true);
        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(BURN_ADDRESS, true);

        // set amm pair
        _setAutomatedMarketMakerPair(address(_uniswapPair), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, MAX_SUPPLY);
    }

    // receive
    receive() external payable {}

    // transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0)) {
            revert ERC20FromZero();
        }
        if (to == address(0)) {
            revert ERC20ToZero();
        }

        // zero amount
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuying = automatedMarketMakerPairs[from] &&
            !isExcludedMaxTransactionAmount[to];
        bool isSelling = automatedMarketMakerPairs[to] &&
            !isExcludedMaxTransactionAmount[from];

        bool isOwner = from == owner() || to == owner();
        bool isBurning = to == BURN_ADDRESS;

        // check limits
        if (limitsEnabled && !isSwapping && !isOwner && !isBurning) {
            if (!tradingEnabled) {
                if (!isExcludedFromFees[from] && !isExcludedFromFees[to]) {
                    revert TradingNotActive();
                }
            }

            if (isBuying) {
                if (amount > maxTransactionAmount) {
                    revert BuyTransferExceedsMaxTransactionAmount();
                }
                if (amount + balanceOf(to) > maxWallet) {
                    revert BuyExceedsMaxWallet();
                }
            } else if (isSelling) {
                if (amount > maxTransactionAmount) {
                    revert SellTransferExceedsMaxTransactionAmount();
                }
            } else if (!isExcludedMaxTransactionAmount[to]) {
                if (amount + balanceOf(to) > maxWallet) {
                    revert MaxWallet();
                }
            }
        }

        // swap
        if (
            swapEnabled &&
            balanceOf(address(this)) >= swapTokensAtAmount &&
            !isSwapping &&
            !automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            isSwapping = true;
            _swap();
            isSwapping = false;
        }

        // fees
        uint256 fees = 0;
        if (
            !isSwapping && !isExcludedFromFees[from] && !isExcludedFromFees[to]
        ) {
            // only take fees on buys/sells, never on wallet transfers
            uint256 sellTotalFees = sellLiquidityFee + sellDevFee;
            uint256 buyTotalFees = buyLiquidityFee + buyDevFee;

            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                super._transfer(from, address(this), fees);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount - fees);
    }

    // owners only
    function excludeFromMaxTransaction(
        address addr,
        bool excluded
    ) public onlyOwner {
        isExcludedMaxTransactionAmount[addr] = excluded;
        emit ExcludeFromMaxTransaction(addr, excluded);
    }

    function excludeFromFees(address addr, bool excluded) public onlyOwner {
        isExcludedFromFees[addr] = excluded;
        emit ExcludeFromFees(addr, excluded);
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        swapEnabled = true;
    }

    function removeLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function setFees(
        uint256 _buyLiquidityFee,
        uint256 _buyDevFee,
        uint256 _sellLiquidityFee,
        uint256 _sellDevFee
    ) external onlyOwner {
        if (buyLiquidityFee + buyDevFee > MAX_TOTAL_FEE) {
            revert FeeTooHigh();
        }
        if (sellLiquidityFee + sellDevFee > MAX_TOTAL_FEE) {
            revert FeeTooHigh();
        }

        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        if (newAmount < _totalSupply / 100000) {
            revert SwapAmountTooLow();
        }
        if (newAmount > (_totalSupply * 5) / 1000) {
            revert SwapAmountTooHigh();
        }
        swapTokensAtAmount = newAmount;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setMaxTransactionAmount(uint256 max) external onlyOwner {
        maxTransactionAmount = max;
    }

    function setMaxWallet(uint256 max) external onlyOwner {
        maxWallet = max;
    }

    // private
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        _approve(address(this), address(UNISWAP_V2_ROUTER), tokenAmount);

        // make the swap
        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer
        _approve(address(this), address(UNISWAP_V2_ROUTER), tokenAmount);

        // add liquidity
        UNISWAP_V2_ROUTER.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            DEV_WALLET,
            block.timestamp
        );
    }

    function _swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForDev;

        // nothing to swap
        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // swap amount
        uint256 swapAmount = contractBalance;
        if (swapAmount > swapTokensAtAmount * 20) {
            swapAmount = swapTokensAtAmount * 20;
        }

        // split liquidity tokens - 0.5 keep as is, 0.5 swap to ETH
        uint256 totalLiquidityTokens = (swapAmount * tokensForLiquidity) /
            totalTokensToSwap;
        uint256 liquidityTokens = totalLiquidityTokens / 2;

        uint256 devTokens = swapAmount - totalLiquidityTokens;
        uint256 liquidityETHTokens = totalLiquidityTokens - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(devTokens + liquidityETHTokens);
        uint256 gainedETH = address(this).balance - initialETHBalance;

        uint256 ethForLiquidity = (gainedETH * liquidityETHTokens) /
            (liquidityETHTokens + devTokens);

        // reset states
        tokensForLiquidity = 0;
        tokensForDev = 0;

        // add liquidity
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                devTokens + liquidityETHTokens,
                gainedETH,
                liquidityTokens
            );
        }

        // dev transfer
        payable(address(DEV_WALLET)).transfer(address(this).balance);
    }
}