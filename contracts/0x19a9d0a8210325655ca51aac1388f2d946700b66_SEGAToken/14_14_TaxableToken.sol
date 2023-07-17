// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ERC20Base.sol";
import "./TaxDistributor.sol";

/*
 * TaxableToken: Add a tax on buy, sell or transfer
 */
abstract contract TaxableToken is ERC20Base, TaxDistributor {
    struct FeeConfiguration {
        bool feesInToken; // if set to true, collectors will get tokens, if false collector the fee will be swapped for the native currency
        uint16 buyFees; // fees applied during buys, from 0 to 2000 (ie, 100 = 1%)
        uint16 sellFees; // fees applied during sells, from 0 to 2000 (ie, 100 = 1%)
        uint16 transferFees; // fees applied during transfers, from 0 to 2000 (ie, 100 = 1%)
        uint16 burnFeeRatio; // from 0 to 10000 (ie 8000 = 80% of the fee collected are burned)
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

    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) private _lpPools;

    event FeeConfigurationUpdated(FeeConfiguration configuration);
    event SwapRouterUpdated(address indexed router, address indexed pair);
    event ExcludedFromFees(address indexed account, bool excluded);
    event SetLpPool(address indexed pairAddress, bool isLp);

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
        swapPair = _pairFor(swapRouter.factory(), address(this), swapRouter.WETH());
        _lpPools[swapPair] = true;

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

    function _setIsLpPool(address pairAddress, bool isLp) internal {
        require(_lpPools[pairAddress] != isLp, "Already set");
        _lpPools[pairAddress] = isLp;
        emit SetLpPool(pairAddress, isLp);
    }

    function isLpPool(address pairAddress) public view returns (bool) {
        return _lpPools[pairAddress];
    }

    function _setSwapRouter(address _newRouter) internal {
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

    function _setFeeConfiguration(FeeConfiguration memory configuration) internal {
        require(configuration.buyFees <= MAX_FEE, "Invalid buy fee");
        require(configuration.sellFees <= MAX_FEE, "Invalid sell fee");
        require(configuration.transferFees <= MAX_FEE, "Invalid transfer fee");

        uint16 totalShare = configuration.burnFeeRatio +
            configuration.liquidityFeeRatio +
            configuration.collectorsFeeRatio;
        require(totalShare == 0 || totalShare == FEE_PRECISION, "Invalid fee share");

        feeConfiguration = configuration;
        emit FeeConfigurationUpdated(configuration);
    }

    function _processFees(uint256 tokenAmount, uint256 minAmountOut) internal lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenAmount) {
            uint256 liquidityAmount = (tokenAmount * feeConfiguration.liquidityFeeRatio) /
                (FEE_PRECISION - feeConfiguration.burnFeeRatio);
            uint256 liquidityTokens = liquidityAmount / 2;

            uint256 collectorsAmount = tokenAmount - liquidityAmount;
            uint256 liquifyAmount = liquidityAmount - liquidityTokens;

            if (!feeConfiguration.feesInToken) {
                liquifyAmount += collectorsAmount;
            }

            // swap tokens
            if (liquifyAmount > 0) {
                if (balanceOf(swapPair) == 0) {
                    // do not swap before the pair has liquidity
                    return;
                }

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

            if (feeConfiguration.feesInToken) {
                // send tokens to fee collectors
                _distributeFees(collectorsAmount, true);
            } else {
                // send remaining ETH to fee collectors
                _distributeFees(address(this).balance, false);
            }
        }
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

    // calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(amount > 0, "Transfer <= 0");

        uint256 taxFee = 0;
        bool processFee = !_processingFees && autoProcessFees;

        if (!_processingFees) {
            bool fromExcluded = isExcludedFromFees(from);
            bool toExcluded = isExcludedFromFees(to);

            bool fromLP = isLpPool(from);
            bool toLP = isLpPool(to);

            if (fromLP && !toLP && !toExcluded && to != address(swapRouter)) {
                // buy fee
                taxFee = feeConfiguration.buyFees;
            } else if (toLP && !fromExcluded && !toExcluded) {
                // sell fee
                taxFee = feeConfiguration.sellFees;
            } else if (!fromLP && !toLP && from != address(swapRouter) && !fromExcluded) {
                // transfer fee
                taxFee = feeConfiguration.transferFees;
            }
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

            if (burnAmount > 0) {
                taxAmount -= burnAmount;
                super._transfer(from, BURN_ADDRESS, burnAmount);
            }

            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
            }

            if (sendAmount > 0) {
                super._transfer(from, to, sendAmount);
            }
        } else {
            super._transfer(from, to, amount);
        }
    }

    function setAutoprocessFees(bool autoProcess) external virtual;

    function setIsLpPool(address pairAddress, bool isLp) external virtual;

    function setIsExcludedFromFees(address account, bool excluded) external virtual;

    function processFees(uint256 amount, uint256 minAmountOut) external virtual;

    function setLiquidityOwner(address newOwner) external virtual;

    function setNumTokensToSwap(uint256 amount) external virtual;

    function setFeeConfiguration(FeeConfiguration calldata configuration) external virtual;

    function setSwapRouter(address newRouter) external virtual;
}