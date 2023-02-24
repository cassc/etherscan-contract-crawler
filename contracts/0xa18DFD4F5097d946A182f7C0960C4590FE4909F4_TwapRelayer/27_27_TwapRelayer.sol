// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './interfaces/ITwapFactory.sol';
import './interfaces/ITwapDelay.sol';
import './interfaces/ITwapPair.sol';
import './interfaces/ITwapOracleV3.sol';
import './interfaces/ITwapRelayer.sol';
import './interfaces/ITwapRelayerInitializable.sol';
import './interfaces/IWETH.sol';
import './libraries/SafeMath.sol';
import './libraries/Orders.sol';
import './libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';

contract TwapRelayer is ITwapRelayer, ITwapRelayerInitializable {
    using SafeMath for uint256;

    uint256 private constant PRECISION = 10**18;
    uint16 private constant MAX_TOLERANCE = 10;

    /*
     * DO NOT CHANGE THE BELOW STATE VARIABLES.
     * REMOVING, REORDERING OR INSERTING STATE VARIABLES WILL CAUSE STORAGE COLLISION.
     * NEW VARIABLES SHOULD BE ADDED BELOW THESE VARIABLES TO AVOID STORAGE COLLISION.
     */
    uint8 public initialized;
    uint8 private locked;
    address public override owner;
    address public override factory;
    address public override weth;
    address public override delay;
    uint256 public override ethTransferGasCost;
    uint256 public override executionGasLimit;
    uint256 public override gasPriceMultiplier;

    mapping(address => uint256) public override swapFee;
    mapping(address => uint32) public override twapInterval;
    mapping(address => bool) public override isPairEnabled;
    mapping(address => uint256) public override tokenLimitMin;
    mapping(address => uint256) public override tokenLimitMaxMultiplier;
    mapping(address => uint16) public override tolerance;

    /*
     * DO NOT CHANGE THE ABOVE STATE VARIABLES.
     * REMOVING, REORDERING OR INSERTING STATE VARIABLES WILL CAUSE STORAGE COLLISION.
     * NEW VARIABLES SHOULD BE ADDED BELOW THESE VARIABLES TO AVOID STORAGE COLLISION.
     */

    modifier lock() {
        require(locked == 0, 'TR06');
        locked = 1;
        _;
        locked = 0;
    }

    // This contract implements a proxy pattern.
    // The constructor is to set to prevent abuse of this implementation contract.
    // Setting locked = 1 forces core fetures, e.g. buy(), to always revert.
    constructor() {
        owner = msg.sender;
        initialized = 1;
        locked = 1;
    }

    // This function should be called through the proxy contract to initialize the proxy contract's storage.
    function initialize(
        address _factory,
        address _delay,
        address _weth
    ) external override {
        require(initialized == 0, 'TR5B');

        initialized = 1;
        factory = _factory;
        delay = _delay;
        weth = _weth;
        owner = msg.sender;
        ethTransferGasCost = 2600 + 1504; // EIP-2929 acct access cost + Gnosis Safe receive ETH cost;

        emit Initialized(_factory, _delay, _weth);
        emit DelaySet(_delay);
        emit OwnerSet(msg.sender);
        emit EthTransferGasCostSet(ethTransferGasCost);
    }

    function setDelay(address _delay) external override {
        require(msg.sender == owner, 'TR00');
        require(_delay != delay, 'TR01');
        require(_delay != address(0), 'TR02');
        delay = _delay;
        emit DelaySet(_delay);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TR00');
        require(_owner != owner, 'TR01');
        require(_owner != address(0), 'TR02');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setSwapFee(address pair, uint256 fee) external override {
        require(msg.sender == owner, 'TR00');
        require(fee != swapFee[pair], 'TR01');
        swapFee[pair] = fee;
        emit SwapFeeSet(pair, fee);
    }

    function setTwapInterval(address pair, uint32 interval) external override {
        require(msg.sender == owner, 'TR00');
        require(interval != twapInterval[pair], 'TR01');
        // '>' uses less gas than '!=' in 0.7.6
        require(interval > 0, 'TR56');
        twapInterval[pair] = interval;
        emit TwapIntervalSet(pair, interval);
    }

    function setPairEnabled(address pair, bool enabled) external override {
        require(msg.sender == owner, 'TR00');
        require(enabled != isPairEnabled[pair], 'TR01');
        isPairEnabled[pair] = enabled;
        emit PairEnabledSet(pair, enabled);
    }

    function setEthTransferGasCost(uint256 gasCost) external override {
        require(msg.sender == owner, 'TR00');
        require(gasCost != ethTransferGasCost, 'TR01');
        ethTransferGasCost = gasCost;
        emit EthTransferGasCostSet(gasCost);
    }

    function setExecutionGasLimit(uint256 limit) external override {
        require(msg.sender == owner, 'TR00');
        require(limit != executionGasLimit, 'TR01');
        executionGasLimit = limit;
        emit ExecutionGasLimitSet(limit);
    }

    function setGasPriceMultiplier(uint256 multiplier) external override {
        require(msg.sender == owner, 'TR00');
        require(multiplier != gasPriceMultiplier, 'TR01');
        gasPriceMultiplier = multiplier;
        emit GasPriceMultiplierSet(multiplier);
    }

    function setTokenLimitMin(address token, uint256 limit) external override {
        require(msg.sender == owner, 'TR00');
        require(limit != tokenLimitMin[token], 'TR01');
        tokenLimitMin[token] = limit;
        emit TokenLimitMinSet(token, limit);
    }

    function setTokenLimitMaxMultiplier(address token, uint256 multiplier) external override {
        require(msg.sender == owner, 'TR00');
        require(multiplier != tokenLimitMaxMultiplier[token], 'TR01');
        require(multiplier <= PRECISION, 'TR3A');
        tokenLimitMaxMultiplier[token] = multiplier;
        emit TokenLimitMaxMultiplierSet(token, multiplier);
    }

    function setTolerance(address pair, uint16 _tolerance) external override {
        require(msg.sender == owner, 'TR00');
        require(_tolerance != tolerance[pair], 'TR01');
        require(_tolerance <= MAX_TOLERANCE, 'TR54');
        tolerance[pair] = _tolerance;
        emit ToleranceSet(pair, _tolerance);
    }

    function sell(SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        require(
            sellParams.to != sellParams.tokenIn && sellParams.to != sellParams.tokenOut && sellParams.to != address(0),
            'TR26'
        );
        // Duplicate checks in Orders.sell
        // require(sellParams.amountIn != 0, 'TR24');

        if (sellParams.wrapUnwrap && sellParams.tokenIn == weth) {
            require(msg.value == sellParams.amountIn, 'TR59');
        } else {
            require(msg.value == 0, 'TR58');
        }

        (uint256 amountIn, uint256 amountOut, uint256 fee) = swapExactIn(
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.amountIn,
            sellParams.wrapUnwrap,
            sellParams.to
        );
        require(amountOut >= sellParams.amountOutMin, 'TR37');

        orderId = ITwapDelay(delay).sell{ value: calculatePrepay() }(
            Orders.SellParams(
                sellParams.tokenIn,
                sellParams.tokenOut,
                amountIn,
                0, // Relax slippage constraints
                false, // Never wrap/unwrap
                address(this),
                executionGasLimit,
                sellParams.submitDeadline
            )
        );

        emit Sell(
            msg.sender,
            sellParams.tokenIn,
            sellParams.tokenOut,
            amountIn,
            amountOut,
            sellParams.amountOutMin,
            sellParams.wrapUnwrap,
            fee,
            sellParams.to,
            delay,
            orderId
        );
    }

    function buy(BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        require(
            buyParams.to != buyParams.tokenIn && buyParams.to != buyParams.tokenOut && buyParams.to != address(0),
            'TR26'
        );
        // Duplicate checks in Orders.sell
        // require(buyParams.amountOut != 0, 'TR23');

        if (!buyParams.wrapUnwrap || buyParams.tokenIn != weth) {
            require(msg.value == 0, 'TR58');
        }

        uint256 balanceBefore = address(this).balance.sub(msg.value);

        (uint256 amountIn, uint256 amountOut, uint256 fee) = swapExactOut(
            buyParams.tokenIn,
            buyParams.tokenOut,
            buyParams.amountOut,
            buyParams.wrapUnwrap,
            buyParams.to
        );
        require(amountIn <= buyParams.amountInMax, 'TR08');

        orderId = ITwapDelay(delay).sell{ value: calculatePrepay() }(
            Orders.SellParams(
                buyParams.tokenIn,
                buyParams.tokenOut,
                amountIn,
                0, // Relax slippage constraints
                false, // Never wrap/unwrap
                address(this),
                executionGasLimit,
                buyParams.submitDeadline
            )
        );

        emit Buy(
            msg.sender,
            buyParams.tokenIn,
            buyParams.tokenOut,
            amountIn,
            buyParams.amountInMax,
            amountOut,
            buyParams.wrapUnwrap,
            fee,
            buyParams.to,
            delay,
            orderId
        );

        if (buyParams.wrapUnwrap && buyParams.tokenIn == weth) {
            uint256 balanceAfter = address(this).balance;
            if (balanceAfter > balanceBefore) {
                TransferHelper.safeTransferETH(msg.sender, balanceAfter.sub(balanceBefore), ethTransferGasCost);
            }
        }
    }

    function getPair(address tokenA, address tokenB) internal view returns (address pair, bool inverted) {
        inverted = tokenA > tokenB;
        pair = ITwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), 'TR17');
    }

    function calculatePrepay() internal returns (uint256) {
        require(executionGasLimit > 0, 'TR3D');
        require(gasPriceMultiplier > 0, 'TR3C');
        return ITwapDelay(delay).gasPrice().mul(gasPriceMultiplier).mul(executionGasLimit).div(PRECISION);
    }

    function swapExactIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool wrapUnwrap,
        address to
    )
        internal
        returns (
            uint256 _amountIn,
            uint256 _amountOut,
            uint256 fee
        )
    {
        (address pair, bool inverted) = getPair(tokenIn, tokenOut);
        require(isPairEnabled[pair], 'TR5A');

        _amountIn = transferIn(tokenIn, amountIn, wrapUnwrap);

        fee = _amountIn.mul(swapFee[pair]).div(PRECISION);
        uint256 amountInMinusFee = _amountIn.sub(fee);
        uint256 calculatedAmountOut = calculateAmountOut(pair, inverted, amountInMinusFee);
        _amountOut = transferOut(to, tokenOut, calculatedAmountOut, wrapUnwrap);

        require(_amountOut <= calculatedAmountOut.add(tolerance[pair]), 'TR2E');
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        bool wrapUnwrap,
        address to
    )
        internal
        returns (
            uint256 _amountIn,
            uint256 _amountOut,
            uint256 fee
        )
    {
        (address pair, bool inverted) = getPair(tokenIn, tokenOut);
        require(isPairEnabled[pair], 'TR5A');

        _amountOut = transferOut(to, tokenOut, amountOut, wrapUnwrap);
        uint256 calculatedAmountIn = calculateAmountIn(pair, inverted, _amountOut);

        uint256 amountInPlusFee = calculatedAmountIn.mul(PRECISION).ceil_div(PRECISION.sub(swapFee[pair]));
        fee = amountInPlusFee.sub(calculatedAmountIn);
        _amountIn = transferIn(tokenIn, amountInPlusFee, wrapUnwrap);

        require(_amountIn >= amountInPlusFee.sub(tolerance[pair]), 'TR2E');
    }

    function calculateAmountIn(
        address pair,
        bool inverted,
        uint256 amountOut
    ) internal view returns (uint256 amountIn) {
        (uint8 xDecimals, uint8 yDecimals, uint256 price) = getPriceByPairAddress(pair, inverted);
        uint256 decimalsConverter = getDecimalsConverter(xDecimals, yDecimals, inverted);
        amountIn = amountOut.mul(decimalsConverter).ceil_div(price);
    }

    function calculateAmountOut(
        address pair,
        bool inverted,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        (uint8 xDecimals, uint8 yDecimals, uint256 price) = getPriceByPairAddress(pair, inverted);
        uint256 decimalsConverter = getDecimalsConverter(xDecimals, yDecimals, inverted);
        amountOut = amountIn.mul(price).div(decimalsConverter);
    }

    function getDecimalsConverter(
        uint8 xDecimals,
        uint8 yDecimals,
        bool inverted
    ) internal pure returns (uint256 decimalsConverter) {
        decimalsConverter = 10**(18 + (inverted ? yDecimals - xDecimals : xDecimals - yDecimals));
    }

    function getPriceByPairAddress(address pair, bool inverted)
        public
        view
        override
        returns (
            uint8 xDecimals,
            uint8 yDecimals,
            uint256 price
        )
    {
        uint256 spotPrice;
        uint256 averagePrice;
        (spotPrice, averagePrice, xDecimals, yDecimals) = getPricesFromOracle(pair);

        if (inverted) {
            price = uint256(10**36).div(spotPrice > averagePrice ? spotPrice : averagePrice);
        } else {
            price = spotPrice < averagePrice ? spotPrice : averagePrice;
        }
    }

    function getPriceByTokenAddresses(address tokenIn, address tokenOut) public view override returns (uint256 price) {
        (address pair, bool inverted) = getPair(tokenIn, tokenOut);
        (, , price) = getPriceByPairAddress(pair, inverted);
    }

    function getPoolState(address token0, address token1)
        external
        view
        override
        returns (
            uint256 price,
            uint256 fee,
            uint256 limitMin0,
            uint256 limitMax0,
            uint256 limitMin1,
            uint256 limitMax1
        )
    {
        (address pair, ) = getPair(token0, token1);
        require(isPairEnabled[pair], 'TR5A');

        fee = swapFee[pair];

        price = getPriceByTokenAddresses(token0, token1);

        limitMin0 = tokenLimitMin[token0];
        limitMax0 = IERC20(token0).balanceOf(address(this)).mul(tokenLimitMaxMultiplier[token0]).div(PRECISION);
        limitMin1 = tokenLimitMin[token1];
        limitMax1 = IERC20(token1).balanceOf(address(this)).mul(tokenLimitMaxMultiplier[token1]).div(PRECISION);
    }

    function quoteSell(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256 amountOut) {
        require(amountIn > 0, 'TR24');

        (address pair, bool inverted) = getPair(tokenIn, tokenOut);

        uint256 fee = amountIn.mul(swapFee[pair]).div(PRECISION);
        uint256 amountInMinusFee = amountIn.sub(fee);
        amountOut = calculateAmountOut(pair, inverted, amountInMinusFee);
        checkLimits(tokenOut, amountOut);
    }

    function quoteBuy(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view override returns (uint256 amountIn) {
        require(amountOut > 0, 'TR23');

        (address pair, bool inverted) = getPair(tokenIn, tokenOut);

        checkLimits(tokenOut, amountOut);
        uint256 calculatedAmountIn = calculateAmountIn(pair, inverted, amountOut);
        amountIn = calculatedAmountIn.mul(PRECISION).ceil_div(PRECISION.sub(swapFee[pair]));
    }

    function getPricesFromOracle(address pair)
        internal
        view
        returns (
            uint256 spotPrice,
            uint256 averagePrice,
            uint8 xDecimals,
            uint8 yDecimals
        )
    {
        ITwapOracleV3 oracle = ITwapOracleV3(ITwapPair(pair).oracle());

        xDecimals = oracle.xDecimals();
        yDecimals = oracle.yDecimals();

        spotPrice = oracle.getSpotPrice();

        address uniswapPair = oracle.uniswapPair();
        averagePrice = getAveragePrice(pair, uniswapPair, getDecimalsConverter(xDecimals, yDecimals, false));
    }

    function getAveragePrice(
        address pair,
        address uniswapPair,
        uint256 decimalsConverter
    ) internal view returns (uint256) {
        uint32 secondsAgo = twapInterval[pair];
        require(secondsAgo > 0, 'TR55');
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapPair).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) --arithmeticMeanTick;

        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            return FullMath.mulDiv(ratioX192, decimalsConverter, 2**192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 2**64);
            return FullMath.mulDiv(ratioX128, decimalsConverter, 2**128);
        }
    }

    function transferIn(
        address token,
        uint256 amount,
        bool wrap
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == weth) {
            if (wrap) {
                require(msg.value >= amount, 'TR03');
                IWETH(token).deposit{ value: amount }();
            } else {
                TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceAfter > balanceBefore, 'TR2C');
            return balanceAfter.sub(balanceBefore);
        }
    }

    function transferOut(
        address to,
        address token,
        uint256 amount,
        bool unwrap
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        checkLimits(token, amount);

        if (token == weth) {
            if (unwrap) {
                IWETH(token).withdraw(amount);
                TransferHelper.safeTransferETH(to, amount, ethTransferGasCost);
            } else {
                TransferHelper.safeTransfer(token, to, amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            TransferHelper.safeTransfer(token, to, amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceBefore > balanceAfter, 'TR2C');
            return balanceBefore.sub(balanceAfter);
        }
    }

    function checkLimits(address token, uint256 amount) internal view {
        require(amount >= tokenLimitMin[token], 'TR03');
        require(
            amount <= IERC20(token).balanceOf(address(this)).mul(tokenLimitMaxMultiplier[token]).div(PRECISION),
            'TR3A'
        );
    }

    function approve(
        address token,
        uint256 amount,
        address to
    ) external override lock {
        require(msg.sender == owner, 'TR00');
        require(to != address(0), 'TR02');

        TransferHelper.safeApprove(token, to, amount);

        emit Approve(token, to, amount);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external override lock {
        require(msg.sender == owner, 'TR00');
        require(to != address(0), 'TR02');
        if (token == address(0)) {
            TransferHelper.safeTransferETH(to, amount, ethTransferGasCost);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
        emit Withdraw(token, to, amount);
    }

    receive() external payable {}
}