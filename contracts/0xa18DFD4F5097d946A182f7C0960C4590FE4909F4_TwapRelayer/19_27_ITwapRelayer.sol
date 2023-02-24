// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import '../libraries/Orders.sol';

interface ITwapRelayer {
    event OwnerSet(address owner);
    event DelaySet(address delay);
    event PairEnabledSet(address pair, bool enabled);
    event SwapFeeSet(address pair, uint256 fee);
    event TwapIntervalSet(address pair, uint32 interval);
    event EthTransferGasCostSet(uint256 gasCost);
    event ExecutionGasLimitSet(uint256 limit);
    event GasPriceMultiplierSet(uint256 multiplier);
    event TokenLimitMinSet(address token, uint256 limit);
    event TokenLimitMaxMultiplierSet(address token, uint256 limit);
    event ToleranceSet(address pair, uint16 tolerance);
    event Approve(address token, address to, uint256 amount);
    event Withdraw(address token, address to, uint256 amount);
    event Sell(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutMin,
        bool wrapUnwrap,
        uint256 fee,
        address indexed to,
        address orderContract,
        uint256 indexed orderId
    );
    event Buy(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountInMax,
        uint256 amountOut,
        bool wrapUnwrap,
        uint256 fee,
        address indexed to,
        address orderContract,
        uint256 indexed orderId
    );

    function factory() external view returns (address);

    function delay() external view returns (address);

    function setDelay(address _delay) external;

    function weth() external view returns (address);

    function owner() external view returns (address);

    function setOwner(address _owner) external;

    function swapFee(address pair) external view returns (uint256);

    function setSwapFee(address pair, uint256 fee) external;

    function twapInterval(address pair) external view returns (uint32);

    function setTwapInterval(address pair, uint32 _interval) external;

    function isPairEnabled(address pair) external view returns (bool);

    function setPairEnabled(address pair, bool enabled) external;

    function ethTransferGasCost() external view returns (uint256);

    function setEthTransferGasCost(uint256 gasCost) external;

    function executionGasLimit() external view returns (uint256);

    function setExecutionGasLimit(uint256 limit) external;

    function gasPriceMultiplier() external view returns (uint256);

    function setGasPriceMultiplier(uint256 multiplier) external;

    function tokenLimitMin(address token) external view returns (uint256);

    function setTokenLimitMin(address token, uint256 limit) external;

    function tokenLimitMaxMultiplier(address token) external view returns (uint256);

    function setTokenLimitMaxMultiplier(address token, uint256 multiplier) external;

    function tolerance(address pair) external view returns (uint16);

    function setTolerance(address pair, uint16 _tolerance) external;

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint32 submitDeadline;
    }

    function sell(SellParams memory sellParams) external payable returns (uint256 orderId);

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint32 submitDeadline;
    }

    function buy(BuyParams memory buyParams) external payable returns (uint256 orderId);

    function getPriceByPairAddress(address pair, bool inverted)
        external
        view
        returns (
            uint8 xDecimals,
            uint8 yDecimals,
            uint256 price
        );

    function getPriceByTokenAddresses(address tokenIn, address tokenOut) external view returns (uint256 price);

    function getPoolState(address token0, address token1)
        external
        view
        returns (
            uint256 price,
            uint256 fee,
            uint256 limitMin0,
            uint256 limitMax0,
            uint256 limitMin1,
            uint256 limitMax1
        );

    function quoteSell(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function quoteBuy(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function approve(
        address token,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external;
}