// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./FeeDistributor.sol";
import "./RewardToken.sol";

/*
 * TaxToken
 * Based on the configuration, a part of each transaction (buy, sell, transfer) is burned, added to the liquidity pool , used for yield rewards and sent to the collectors (ie team)
 */
abstract contract TaxToken is Ownable, FeeDistributor, RewardToken {
    struct FeeConfiguration {
        uint16 buyFees; // fees applied during buys, from 0 to 2000 (ie, 100 = 1%)
        uint16 sellFees; // fees applied during sells, from 0 to 2000 (ie, 100 = 1%)
        uint16 transferFees; // fees applied during transfers, from 0 to 2000 (ie, 100 = 1%)
        uint16 burnFeeRatio; // from 0 to 10000 (ie 8000 = 80% of the fee collected are burned)
        uint16 rewardsFeeRatio; // from 0 to 10000 (ie 8000 = 80% of the fee collected are used for passive rewards)
        uint16 liquidityFeeRatio; // from 0 to 10000 (ie 8000 = 80% of the fee collected are added back to liquidity)
        uint16 collectorsFeeRatio; // from 0 to 10000 (ie 8000 = 80% of the fee collected are sent to fee collectors)
    }

    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    uint16 public constant MAX_FEE = 2000; // max 20% fees
    uint16 public constant FEE_PRECISION = 10000;

    // swap config
    IUniswapV2Router02 public swapRouter;
    address public swapPair;
    address public liquidityOwner;

    // fees
    bool private _processingFees;
    bool public autoProcessFees;
    uint256 public numTokensToSwap; // amount of tokens to collect before processing fees (default to 0.05% of supply)
    FeeConfiguration public feeConfiguration;

    uint256 public tradeStartBlock;

    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) private _lpPools;
    mapping(address => bool) private _bots;

    event FeeConfigurationUpdated(FeeConfiguration configuration);
    event SwapRouterUpdated(address indexed router, address indexed pair);
    event ExcludedFromFees(address indexed account, bool excluded);
    event SetLpPool(address indexed pairAddress, bool isLp);
    event SetIsBot(address indexed account, bool isBot);

    modifier lockTheSwap() {
        _processingFees = true;
        _;
        _processingFees = false;
    }

    constructor(
        bool autoProcessFees_,
        uint256 numTokensToSwap_,
        address swapRouter_,
        FeeConfiguration memory feeConfiguration_
    ) {
        numTokensToSwap = numTokensToSwap_;
        autoProcessFees = autoProcessFees_;

        liquidityOwner = _msgSender();

        // Create a uniswap pair for this new token
        swapRouter = IUniswapV2Router02(swapRouter_);
        swapPair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), swapRouter.WETH());
        _lpPools[address(swapPair)] = true;

        // configure addresses excluded from fee
        _setIsExcludedFromFees(_msgSender(), true);
        _setIsExcludedFromFees(address(this), true);

        // configure fees
        _setFeeConfiguration(feeConfiguration_);
    }

    // receive ETH when swaping
    receive() external payable {}

    function isExcludedFromFees(address account) public view returns (bool) {
        return _excludedFromFees[account];
    }

    function _setIsExcludedFromFees(address account, bool excluded) internal {
        require(_excludedFromFees[account] != excluded, "Already set");
        _excludedFromFees[account] = excluded;
        emit ExcludedFromFees(account, excluded);
    }

    function setIsExcludedFromFees(address account, bool excluded) external onlyOwner {
        _setIsExcludedFromFees(account, excluded);
    }

    function isLpPool(address pairAddress) public view returns (bool) {
        return _lpPools[pairAddress];
    }

    function setIsLpPool(address pairAddress, bool isLp) external onlyOwner {
        require(_lpPools[pairAddress] != isLp, "Already set");
        _lpPools[pairAddress] = isLp;
        emit SetLpPool(pairAddress, isLp);
    }

    function isBot(address account) public view returns (bool) {
        return _bots[account];
    }

    function _setIsBot(address account, bool bot) internal {
        require(_bots[account] != bot, "Already set");
        _bots[account] = bot;
        emit SetIsBot(account, bot);
    }

    function setIsBot(address account, bool bot) external onlyOwner {
        _setIsBot(account, bot);
    }

    function updateSwapRouter(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Invalid router");

        swapRouter = IUniswapV2Router02(_newRouter);
        IUniswapV2Factory factory = IUniswapV2Factory(swapRouter.factory());
        require(address(factory) != address(0), "Invalid factory");

        address weth = swapRouter.WETH();
        swapPair = factory.getPair(address(this), weth);
        if (swapPair == address(0)) {
            swapPair = factory.createPair(address(this), weth);
        }

        require(swapPair != address(0), "Invalid pair address.");
        emit SwapRouterUpdated(address(swapRouter), swapPair);
    }

    function _setFeeConfiguration(FeeConfiguration memory configuration) private {
        require(configuration.buyFees <= MAX_FEE, "Invalid buy fee");
        require(configuration.sellFees <= MAX_FEE, "Invalid sell fee");
        require(configuration.transferFees <= MAX_FEE, "Invalid transfer fee");

        uint16 totalShare = configuration.burnFeeRatio +
            configuration.rewardsFeeRatio +
            configuration.liquidityFeeRatio +
            configuration.collectorsFeeRatio;
        require(totalShare == 0 || totalShare == FEE_PRECISION, "Invalid fee share");

        feeConfiguration = configuration;
        emit FeeConfigurationUpdated(configuration);
    }

    function setFeeConfiguration(FeeConfiguration calldata configuration) external onlyOwner {
        _setFeeConfiguration(configuration);
    }

    function _processFees(uint256 tokenAmount, uint256 minAmountOut) private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenAmount) {
            uint256 liquidityAmount = (tokenAmount * feeConfiguration.liquidityFeeRatio) /
                (FEE_PRECISION - feeConfiguration.burnFeeRatio - feeConfiguration.rewardsFeeRatio);
            uint256 liquidityTokens = liquidityAmount / 2;

            uint256 collectorsAmount = tokenAmount - liquidityAmount;
            uint256 liquifyAmount = liquidityAmount - liquidityTokens + collectorsAmount;

            // swap tokens
            if (liquifyAmount > 0) {
                // capture the contract's current balance.
                uint256 initialBalance = address(this).balance;

                _swapTokensForEth(liquifyAmount, minAmountOut);

                // how much did we just swap into?
                uint256 swapBalance = address(this).balance - initialBalance;

                // add liquidity
                uint256 liquidityETH = (swapBalance * liquidityTokens) / liquifyAmount;
                if (liquidityETH > 0) {
                    _addLiquidity(liquidityTokens, liquidityETH);
                }
            }

            // send remaining ETH to fee collectors
            _distributeFees(address(this).balance);
        }
    }

    function processFees(uint256 amount, uint256 minAmountOut) external onlyOwner {
        require(amount <= balanceOf(address(this)), "Amount too high");
        _processFees(amount, minAmountOut);
    }

    function setAutoprocessFees(bool autoProcess) external onlyOwner {
        require(autoProcessFees != autoProcess, "Already set");
        autoProcessFees = autoProcess;
    }

    function setNumTokensToSwap(uint256 amount) external onlyOwner {
        numTokensToSwap = amount;
    }

    function setLiquidityOwner(address newOwner) external onlyOwner {
        liquidityOwner = newOwner;
    }

    /// @dev Swap tokens for eth
    function _swapTokensForEth(uint256 tokenAmount, uint256 minAmountOut) private {
        // generate the swap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapRouter), tokenAmount);

        // add the liquidity
        swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityOwner,
            block.timestamp
        );
    }

    function _executeTransfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "Transfer <= 0");

        uint256 taxFee = 0;
        bool processFee = !_processingFees && autoProcessFees && tradeStartBlock > 0;
        bool bot = _bots[from] || _bots[to];

        if (!_processingFees) {
            bool fromExcluded = isExcludedFromFees(from);
            bool toExcluded = isExcludedFromFees(to);

            bool fromLP = isLpPool(from);
            bool toLP = isLpPool(to);

            if (toLP && tradeStartBlock == 0) {
                tradeStartBlock = block.number;
            }

            if (fromLP && !toLP && !toExcluded && to != address(swapRouter)) {
                // buy fee
                taxFee = feeConfiguration.buyFees;
                // flag sniper bots when buying in the first 2 blocks
                if (!bot && block.number <= tradeStartBlock + 1) {
                    _setIsBot(to, true);
                    _setIsExcludedFromRewards(to, true);
                    bot = true;
                }
            } else if (toLP && !fromExcluded && !toExcluded) {
                // sell fee
                taxFee = feeConfiguration.sellFees;
            } else if (!fromLP && !toLP && from != address(swapRouter) && !fromExcluded) {
                // transfer fee
                taxFee = feeConfiguration.transferFees;
            }
        }

        // apply max fees to bots
        if (bot) {
            taxFee = MAX_FEE;
        }

        // process fees
        if (processFee && taxFee > 0 && !_lpPools[from]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance >= numTokensToSwap) {
                _processFees(numTokensToSwap, 0);
            }
        }

        if (taxFee > 0) {
            uint256 taxAmount = (amount * taxFee) / FEE_PRECISION;
            uint256 sendAmount = amount - taxAmount;
            uint256 burnAmount = (taxAmount * feeConfiguration.burnFeeRatio) / FEE_PRECISION;
            uint256 rewardAmount = (taxAmount * feeConfiguration.rewardsFeeRatio) / FEE_PRECISION;

            if (rewardAmount > 0) {
                taxAmount -= rewardAmount;
                sendAmount += rewardAmount;
            }

            if (burnAmount > 0) {
                taxAmount -= burnAmount;
                _executeTokenTransfer(from, BURN_ADDRESS, burnAmount, 0);
            }

            if (taxAmount > 0) {
                _executeTokenTransfer(from, address(this), taxAmount, 0);
            }

            if (sendAmount > 0) {
                _executeTokenTransfer(from, to, sendAmount, rewardAmount);
            }
        } else {
            _executeTokenTransfer(from, to, amount, 0);
        }
    }
}