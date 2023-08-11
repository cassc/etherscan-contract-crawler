// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*
    $STRONGX

    Website: /
    Twitter: /
    Telegram: /
*/

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/ISwapManager.sol";

contract StrongX is ERC20PresetMinterPauser, Ownable {
    using SafeMath for uint;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable WETH;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;

    ISwapManager public swapManager;
    uint public maxTransactionAmount;
    uint public swapTokensAtAmount;
    uint public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    uint public launchBlock;
    uint public delayBlocks = 20;

    uint public totalFees;
    uint public marketingFee;
    uint public liquidityFee;

    uint public tokensForMarketing;
    uint public tokensForLiquidity;

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapManagerUpdated(
        address indexed newManager,
        address indexed oldManager
    );

    event MarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event BuybackWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint tokensSwapped,
        uint wethReceived,
        uint tokensIntoLiquidity
    );

    constructor() ERC20PresetMinterPauser("StrongX", "STRONGX") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        WETH = _uniswapV2Router.WETH();

        address pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), WETH);
            
        uniswapV2Pair = pair;
        excludeFromMaxTransaction(pair, true);
        _setAutomatedMarketMakerPair(pair, true);

        uint totalSupply = 175_000 * 1e18;

        maxTransactionAmount = totalSupply / 100;
        maxWallet = totalSupply / 100;
        swapTokensAtAmount = totalSupply / 2000;

        marketingFee = 20; // 20% for launch, 1% afterwards
        liquidityFee = 20; // 20% for launch, 1% afterwards
        totalFees = marketingFee + liquidityFee;

        marketingWallet = address(0x90f01C9cd03E01A3d9718B614A3059C82B1df595);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(marketingWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require (
            address(swapManager) != address(0), 
            "Need to set swap manager"
        );
        tradingActive = true;
        swapEnabled = true;
        launchBlock = block.number;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateSwapManager(address newManager) external onlyOwner {
        emit SwapManagerUpdated(newManager, address(swapManager));
        swapManager = ISwapManager(newManager);
        excludeFromFees(newManager, true);
        excludeFromMaxTransaction(newManager, true);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    {
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }

                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            if (totalFees != 2 && 
                launchBlock + delayBlocks < block.number) 
            {
                marketingFee = 1;
                liquidityFee = 1;
                totalFees = 2;
            }

            if ((automatedMarketMakerPairs[to] ||
                automatedMarketMakerPairs[from]) && 
                totalFees > 0) 
            {
                fees = amount.mul(totalFees).div(100);
                tokensForMarketing += (fees * marketingFee) / totalFees;
                tokensForLiquidity += (fees * liquidityFee) / totalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapBack() private {
        uint contractBalance = balanceOf(address(this));
        uint totalTokensToSwap = tokensForMarketing +
            tokensForLiquidity;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }

        uint liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap / 2;
        uint amountToSwapForWeth = contractBalance.sub(liquidityTokens);

        uint initialWethBalance = IERC20(WETH).balanceOf(address(this));
        _approve(address(this), address(swapManager), amountToSwapForWeth);
        swapManager.swapToWeth(amountToSwapForWeth);

        uint wethDelta = IERC20(WETH).balanceOf(address(this)).sub(initialWethBalance);
        uint wethForMarketing = wethDelta.mul(tokensForMarketing).div(totalTokensToSwap);
        uint wethForLiquidity = wethDelta - wethForMarketing;

        tokensForMarketing = 0;
        tokensForLiquidity = 0;

        IERC20(WETH).transfer(marketingWallet, wethForMarketing);

        if (liquidityTokens > 0 && wethForLiquidity > 0) {
            _approve(address(this), address(swapManager), liquidityTokens);
            IERC20(WETH).approve(address(swapManager), wethForLiquidity);
            swapManager.addLiquidity(liquidityTokens, wethForLiquidity);

            emit SwapAndLiquify(
                amountToSwapForWeth,
                wethForLiquidity,
                tokensForLiquidity
            );
        }
    }

    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(this), "Can not rescue own token!");
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}