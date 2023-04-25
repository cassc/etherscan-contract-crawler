// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IUniswapV2Router02, IUniswapV2Factory} from "./interfaces.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";

// https://twitter.com/meowcoineth
// https://t.me/meowcoineth

contract Meow is ERC20, Ownable {
    // events
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool excluded);
    event ExcludeFromMaxTransaction(address indexed account, bool excluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    // errors
    error ERC20FromZero();
    error ERC20ToZero();
    error TradingNotActive();
    error BuyTransferExceedsMaxTransactionAmount();
    error BuyExceedsMaxWallet();
    error SellTransferExceedsMaxTransactionAmount();
    error MaxWallet();
    error SwapAmountTooLow();
    error SwapAmountTooHigh();

    // constants
    uint256 public constant MAX_SUPPLY = 999_999_999 ether;
    address constant DEV_WALLET = 0x888c523E4031A09B94DfCE14EA01Da931e88dF34;
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;
    address private constant BURN_ADDRESS = address(0xdEaD);

    uint256 private constant INITIAL_MAX_TRANSACTION_AMOUNT = 30_000_000 ether; // 3%
    uint256 private constant INITIAL_MAX_WALLET = 30_000_000 ether; // 3%

    uint256 private constant INITIAL_BUY_FEE = 20;
    uint256 private constant INITIAL_SELL_FEE = 50;

    // states
    bool public tradingEnabled = false;
    bool public swapEnabled = false;
    bool public limitsEnabled = true;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    uint256 public buyFee;
    uint256 public sellFee;

    uint256 public tokensForDev;

    bool private _isSwapping;

    // - exclude from fees and max transaction amount
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // - store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    //   could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // constructor
    constructor() ERC20("Meow", unicode"MEOW") {
        // create uniswap pair
        address _uniswapPair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;

        // initialize states
        maxTransactionAmount = INITIAL_MAX_TRANSACTION_AMOUNT;
        maxWallet = INITIAL_MAX_WALLET;
        swapTokensAtAmount = MAX_SUPPLY / 1000; // 0.1% swap wallet

        buyFee = INITIAL_BUY_FEE;
        sellFee = INITIAL_SELL_FEE;

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

        // mint
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
        if (limitsEnabled && !_isSwapping && !isOwner && !isBurning) {
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
            !_isSwapping &&
            !automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            _isSwapping = true;
            _swap();
            _isSwapping = false;
        }

        // fees
        uint256 fees = 0;
        if (
            !_isSwapping && !isExcludedFromFees[from] && !isExcludedFromFees[to]
        ) {
            // only take fees on buys/sells, never on wallet transfers
            uint256 sellTotalFees = sellFee;
            uint256 buyTotalFees = buyFee;

            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForDev += fees;
                super._transfer(from, address(this), fees);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForDev += fees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount - fees);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
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

    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        buyFee = _buyFee;
        sellFee = _sellFee;
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

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
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

    function _swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForDev;

        // nothing to swap
        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // swap amount
        uint256 swapAmount = contractBalance;
        if (swapAmount > swapTokensAtAmount * 20) {
            swapAmount = swapTokensAtAmount * 20;
        }

        // swap to ETH
        _swapTokensForEth(swapAmount);

        // reset states
        tokensForDev = 0;

        // dev transfer
        payable(address(DEV_WALLET)).transfer(address(this).balance);
    }
}