// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

/**
 * Website: https://anonzk.io/
 * Twitter: https://twitter.com/AnonAZK
 * Telegram: https://t.me/AnonZKPortal
 * Docs: https://docs.anonzk.io/
 * 
 *    ▄████████ ███▄▄▄▄    ▄██████▄  ███▄▄▄▄    ▄███████▄     ▄█   ▄█▄ 
 *   ███    ███ ███▀▀▀██▄ ███    ███ ███▀▀▀██▄ ██▀     ▄██   ███ ▄███▀ 
 *   ███    ███ ███   ███ ███    ███ ███   ███       ▄███▀   ███▐██▀   
 *   ███    ███ ███   ███ ███    ███ ███   ███  ▀█▀▄███▀▄▄  ▄█████▀    
 * ▀███████████ ███   ███ ███    ███ ███   ███   ▄███▀   ▀ ▀▀█████▄    
 *   ███    ███ ███   ███ ███    ███ ███   ███ ▄███▀         ███▐██▄   
 *   ███    ███ ███   ███ ███    ███ ███   ███ ███▄     ▄█   ███ ▀███▄ 
 *   ███    █▀   ▀█   █▀   ▀██████▀   ▀█   █▀   ▀████████▀   ███   ▀█▀ 
 *                                                           ▀
 */

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract AnonZK is ERC20, Ownable {
    // events
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool excluded);
    event ExcludeFromMaxTransaction(address indexed account, bool excluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

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
    error MigrationNotEnabled();
    error SupplyExceeded();

    // constants
    uint256 public constant MAX_SUPPLY = 10 * 1e6 ether;
    address constant DEV_WALLET = 0xC8aFc08747213Da2Ab68373E5B261dd304390270;
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;
    address private constant BURN_ADDRESS = address(0xdEaD);
    address private constant AZKV1 = 0x5408245a4D7c685F59cE6D3b8B35916dd6c11A99;

    uint256 private constant INITIAL_MAX_TRANSACTION_AMOUNT = 2 * 1e5 ether; // 2% from total supply maxTransactionAmountTxn
    uint256 private constant INITIAL_MAX_WALLET = 2 * 1e5 ether; // 2% from total supply maxWallet

    uint256 private constant INITIAL_BUY_LIQUIDITY_FEE = 5;
    uint256 private constant INITIAL_BUY_DEV_FEE = 5;

    uint256 private constant INITIAL_SELL_LIQUIDITY_FEE = 10;
    uint256 private constant INITIAL_SELL_DEV_FEE = 10;

    uint256 private constant MAX_TOTAL_FEE = 10;

    // states
    bool public tradingEnabled = false;
    bool public swapEnabled = false;
    bool public limitsEnabled = true;
    bool public migrationEnabled = false;

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
    constructor() ERC20("AnonZK", unicode"AZK") {
        // create uniswap pair
        address _uniswapPair =
            IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());
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
        excludeFromFees(DEV_WALLET, true);
        excludeFromFees(address(this), true);
        excludeFromFees(BURN_ADDRESS, true);
        excludeFromFees(address(0), true);

        excludeFromMaxTransaction(address(UNISWAP_V2_ROUTER), true);
        excludeFromMaxTransaction(address(_uniswapPair), true);
        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(DEV_WALLET, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(BURN_ADDRESS, true);
        excludeFromMaxTransaction(address(0), true);

        // set amm pair
        _setAutomatedMarketMakerPair(address(_uniswapPair), true);
    }

    // receive
    receive() external payable {}

    // migrate
    function migrate(uint256 amount) external {
        if (!migrationEnabled) revert MigrationNotEnabled();

        uint256 _totalSupply = totalSupply();
        if (_totalSupply + amount > MAX_SUPPLY) revert SupplyExceeded();

        IERC20(AZKV1).transferFrom(msg.sender, DEV_WALLET, amount);

        _mint(msg.sender, amount);
    }

    // transfer
    function _transfer(address from, address to, uint256 amount) internal override {
        bool isBuying = automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to];
        bool isSelling = automatedMarketMakerPairs[to] && !isExcludedMaxTransactionAmount[from];

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
            swapEnabled && balanceOf(address(this)) >= swapTokensAtAmount && !isSwapping
                && !automatedMarketMakerPairs[from] && !isExcludedFromFees[from] && !isExcludedFromFees[to]
        ) {
            isSwapping = true;
            _swap();
            isSwapping = false;
        }

        // fees
        uint256 fees = 0;
        if (!isSwapping && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
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
    function excludeFromMaxTransaction(address addr, bool excluded) public onlyOwner {
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

    function setFees(uint256 _buyLiquidityFee, uint256 _buyDevFee, uint256 _sellLiquidityFee, uint256 _sellDevFee)
        external
        onlyOwner
    {
        if (_buyLiquidityFee + _buyDevFee > MAX_TOTAL_FEE) {
            revert FeeTooHigh();
        }
        if (_sellLiquidityFee + _sellDevFee > MAX_TOTAL_FEE) {
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

    function clearStuckBalance() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function clearStuckToken() external onlyOwner {
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function setEnableMigration(bool e) external onlyOwner {
        migrationEnabled = e;
    }

    struct Airdrop {
        uint256 amount;
        address addr;
    }

    function airdrop(Airdrop[] calldata arr) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        uint256 _amount = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            _amount += arr[i].amount;
            if (_totalSupply + _amount > MAX_SUPPLY) revert SupplyExceeded();
            _mint(arr[i].addr, arr[i].amount);
        }
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
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer
        _approve(address(this), address(UNISWAP_V2_ROUTER), tokenAmount);

        // add liquidity
        UNISWAP_V2_ROUTER.addLiquidityETH{value: ethAmount}(
            address(this), tokenAmount, 0, 0, DEV_WALLET, block.timestamp
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
        uint256 totalLiquidityTokens = (swapAmount * tokensForLiquidity) / totalTokensToSwap;
        uint256 liquidityTokens = totalLiquidityTokens / 2;

        uint256 devTokens = swapAmount - totalLiquidityTokens;
        uint256 liquidityETHTokens = totalLiquidityTokens - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(devTokens + liquidityETHTokens);
        uint256 gainedETH = address(this).balance - initialETHBalance;

        uint256 ethForLiquidity = (gainedETH * liquidityETHTokens) / (liquidityETHTokens + devTokens);

        // reset states
        tokensForLiquidity = 0;
        tokensForDev = 0;

        // add liquidity
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(devTokens + liquidityETHTokens, gainedETH, liquidityTokens);
        }

        // dev transfer
        (bool success,) = payable(address(DEV_WALLET)).call{value: address(this).balance}("");
    }
}