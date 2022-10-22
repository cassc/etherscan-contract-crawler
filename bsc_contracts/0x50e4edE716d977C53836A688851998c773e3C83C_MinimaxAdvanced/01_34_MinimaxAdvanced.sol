// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../helpers/RevertLib.sol";
import "../helpers/NativeAddress.sol";

import "../interfaces/IGelatoOps.sol";
import "../interfaces/IPriceOracle.sol";
import "../market/IMarket.sol";
import "../market/Market.sol";

import "./IToken.sol";
import "./IWToken.sol";
import "./MinimaxBase.sol";
import "./MinimaxTreasury.sol";
import "./SwapLib.sol";
import "./PriceLimitLib.sol";

contract MinimaxAdvanced is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IToken;

    // events

    event PositionWasCreatedV2(
        uint indexed positionIndex,
        uint timestamp,
        uint stakeTokenPrice,
        uint8 stakeTokenPriceDecimals
    );

    event PositionWasModified(uint indexed positionIndex);

    event PositionWasClosedV2(
        uint indexed positionIndex,
        uint timestamp,
        uint stakeTokenPrice,
        uint8 stakeTokenPriceDecimals
    );

    event PositionWasLiquidatedV2(
        uint indexed positionIndex,
        uint timestamp,
        uint stakeTokenPrice,
        uint8 stakeTokenPriceDecimals
    );

    event StakeTokenDeposit(uint indexed positionIndex, IToken tokenIn, uint amountIn, IToken tokenOut, uint amountOut);

    event StakeTokenWithdraw(
        uint indexed positionIndex,
        IToken tokenIn,
        uint amountIn,
        IToken tokenOut,
        uint amountOut
    );

    event RewardTokenWithdraw(
        uint indexed positionIndex,
        IToken tokenIn,
        uint amountIn,
        IToken tokenOut,
        uint amountOut
    );

    // storage

    uint public constant MAX_INT = 2**256 - 1;
    uint public constant SLIPPAGE_MULTIPLIER = 1e8;
    uint public constant PRICE_LIMIT_MULTIPLIER = 1e8;

    struct Position {
        address owner;
        uint stopLoss;
        uint takeProfit;
        uint maxSlippage;
        bytes32 gelatoTaskId;
    }

    mapping(uint => Position) public positions;

    mapping(IToken => IPriceOracle) public priceOracles;

    mapping(address => bool) public isLiquidator;

    MinimaxBase public minimaxBase;
    MinimaxTreasury public gasTankTreasury;
    uint public gasTankThreshold;
    IToken public stableToken;
    IMarket public market;
    address public oneInchRouter;
    IGelatoOps public gelatoOps;
    IWToken public wToken;

    // modifiers

    modifier onlyAutomator() {
        require(msg.sender == address(gelatoOps) || isLiquidator[address(msg.sender)], "onlyAutomator");
        _;
    }

    modifier onlyPositionOwner(uint positionIndex) {
        require(positions[positionIndex].owner != address(0), "position not created");
        require(positions[positionIndex].owner == msg.sender, "not position owner");
        _;
    }

    // initializer

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    // management functions

    function setMinimaxBase(MinimaxBase _minimaxBase) external onlyOwner {
        minimaxBase = _minimaxBase;
    }

    function setGasTankTreasury(MinimaxTreasury _gasTankTreasury) external onlyOwner {
        gasTankTreasury = _gasTankTreasury;
    }

    function setGasTankThreshold(uint256 value) external onlyOwner {
        gasTankThreshold = value;
    }

    function setMarket(IMarket _market) external onlyOwner {
        market = _market;
    }

    function setOneInchRouter(address value) external onlyOwner {
        oneInchRouter = value;
    }

    function setLiquidator(address user, bool value) external onlyOwner {
        isLiquidator[user] = value;
    }

    function setStableToken(IToken value) external onlyOwner {
        stableToken = value;
    }

    function setPriceOracles(IToken[] calldata tokens, IPriceOracle[] calldata oracles) external onlyOwner {
        require(tokens.length == oracles.length, "setPriceOracles: tokens.length != oracles.length");
        for (uint32 i = 0; i < tokens.length; i++) {
            priceOracles[tokens[i]] = oracles[i];
        }
    }

    function setGelatoOps(IGelatoOps value) external onlyOwner {
        gelatoOps = value;
    }

    function setWToken(IWToken value) external onlyOwner {
        wToken = value;
    }

    // other functions

    function getPosition(uint positionIndex) external view returns (Position memory) {
        return positions[positionIndex];
    }

    function swapEstimate(
        address inputToken,
        address stakingToken,
        uint inputTokenAmount
    ) public view returns (uint amountOut, bytes memory hints) {
        require(address(market) != address(0), "no market");
        return market.estimateOut(inputToken, stakingToken, inputTokenAmount);
    }

    function marketEstimate(
        IRouter[] memory routers,
        address inputToken,
        address stakingToken,
        uint inputTokenAmount
    ) public view returns (uint amountOut, bytes memory hints) {
        require(address(market) != address(0), "no market");
        return market.estimateOutCustomRouters(routers, inputToken, stakingToken, inputTokenAmount);
    }

    function tokenPrice(IToken token) public view returns (uint price) {
        // try price oracle first
        IPriceOracle priceOracle = priceOracles[token];
        if (address(priceOracle) != address(0)) {
            int price = Math.max(0, priceOracle.latestAnswer());

            return
                _adjustDecimals({
                    value: uint(price),
                    valueDecimals: priceOracle.decimals(),
                    wantDecimals: token.decimals()
                });
        }

        if (address(market) == address(0)) {
            return 0;
        }

        (bool success, bytes memory encodedEstimate) = address(market).staticcall(
            abi.encodeCall(market.estimateOut, (address(token), address(stableToken), 10**token.decimals()))
        );

        if (!success) {
            return 0;
        }

        (uint estimateOut, ) = abi.decode(encodedEstimate, (uint256, bytes));

        return
            _adjustDecimals({
                value: estimateOut,
                valueDecimals: stableToken.decimals(),
                wantDecimals: token.decimals()
            });
    }

    function _adjustDecimals(
        uint value,
        uint8 valueDecimals,
        uint8 wantDecimals
    ) private pure returns (uint) {
        if (wantDecimals > valueDecimals) {
            // if
            // value = 3200
            // valueDecimals = 2
            // wantDecimals = 5
            // then
            // result = 3200000
            return value * (10**(wantDecimals - valueDecimals));
        }

        if (valueDecimals > wantDecimals) {
            // if
            // value = 3200
            // valueDecimals = 4
            // wantDecimals = 2
            // then
            // result = 32
            return value / (10**(valueDecimals - wantDecimals));
        }

        return value;
    }

    // position functions

    struct StakeV2Params {
        address pool;
        bytes poolArgs;
        IToken stakeToken;
        uint stopLossPrice;
        uint takeProfitPrice;
        uint maxSlippage;
        uint stakeTokenPrice;
        SwapLib.SwapParams swapParams;
    }

    function stakeV2(StakeV2Params memory params) public payable nonReentrant returns (uint) {
        // swap
        uint msgValue = msg.value;

        uint actualIn;
        uint actualOut;

        if (address(params.swapParams.tokenIn) == NativeAddress) {
            wToken.deposit{value: params.swapParams.amountIn}();
            msgValue -= params.swapParams.amountIn;
            params.swapParams.tokenIn = wToken;
            (actualIn, actualOut) = SwapLib.swap(params.swapParams, market, oneInchRouter);
            params.swapParams.tokenIn = IToken(NativeAddress);
        } else {
            params.swapParams.tokenIn.safeTransferFrom(msg.sender, address(this), params.swapParams.amountIn);
            (actualIn, actualOut) = SwapLib.swap(params.swapParams, market, oneInchRouter);
        }

        require(msgValue >= gasTankThreshold, "stakeV2: gasTankThreshold");

        // create position
        IToken stakeToken = params.swapParams.tokenOut;
        stakeToken.approve(address(minimaxBase), actualOut);
        uint positionIndex = minimaxBase.create(params.pool, params.poolArgs, stakeToken, actualOut);
        gasTankTreasury.deposit{value: msgValue}(positionIndex);

        bytes32 gelatoTaskId = _gelatoCreateTask(positionIndex);

        positions[positionIndex] = Position({
            owner: msg.sender,
            stopLoss: params.stopLossPrice,
            takeProfit: params.takeProfitPrice,
            maxSlippage: params.maxSlippage,
            gelatoTaskId: gelatoTaskId
        });

        emit StakeTokenDeposit(positionIndex, params.swapParams.tokenIn, actualIn, stakeToken, actualOut);
        emit PositionWasCreatedV2(positionIndex, block.timestamp, params.stakeTokenPrice, stakeToken.decimals());

        return positionIndex;
    }

    function deposit(uint positionIndex, uint amount) external payable nonReentrant onlyPositionOwner(positionIndex) {
        _deposit(positionIndex, amount);
    }

    function _deposit(uint positionIndex, uint amount) private {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        Position storage position = positions[positionIndex];
        if (amount > 0) {
            basePosition.stakeToken.safeTransferFrom(msg.sender, address(this), amount);
            basePosition.stakeToken.approve(address(minimaxBase), amount);
            minimaxBase.deposit(positionIndex, amount);
            emit StakeTokenDeposit(positionIndex, basePosition.stakeToken, amount, basePosition.stakeToken, amount);

            _drainRewardTokens(positionIndex, basePosition, position.owner);
        }
        if (msg.value > 0) {
            gasTankTreasury.deposit{value: msg.value}(positionIndex);
        }
        emit PositionWasModified(positionIndex);
    }

    function estimateLpPartsForPosition(uint positionIndex)
        external
        nonReentrant
        onlyPositionOwner(positionIndex)
        returns (uint, uint)
    {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        _withdraw({
            positionIndex: positionIndex,
            amount: 0,
            amountAll: true,
            liquidation: false,
            swapParams: SwapLib.SwapParams({
                tokenIn: basePosition.stakeToken,
                amountIn: MAX_INT,
                tokenOut: basePosition.stakeToken,
                amountOutMin: 0,
                swapKind: SwapLib.SwapNoSwapKind,
                swapArgs: ""
            }),
            stakeTokenPrice: 0,
            destination: address(this)
        });
        _drainToken(basePosition.stakeToken, address(basePosition.stakeToken));
        return IPairToken(address(basePosition.stakeToken)).burn(address(this));
    }

    function estimateWithdrawalAmountForPosition(uint positionIndex)
        external
        nonReentrant
        onlyPositionOwner(positionIndex)
        returns (uint)
    {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        _withdraw({
            positionIndex: positionIndex,
            amount: 0,
            amountAll: true,
            liquidation: false,
            swapParams: SwapLib.SwapParams({
                tokenIn: basePosition.stakeToken,
                amountIn: MAX_INT,
                tokenOut: basePosition.stakeToken,
                amountOutMin: 0,
                swapKind: SwapLib.SwapNoSwapKind,
                swapArgs: ""
            }),
            stakeTokenPrice: 0,
            destination: address(this)
        });
        return basePosition.stakeToken.balanceOf(address(this));
    }

    struct WithdrawV2Params {
        uint positionIndex;
        uint amount;
        bool amountAll;
        uint stakeTokenPrice;
        SwapLib.SwapParams swapParams;
    }

    function withdrawV2(WithdrawV2Params calldata params)
        external
        nonReentrant
        onlyPositionOwner(params.positionIndex)
    {
        return
            _withdraw({
                positionIndex: params.positionIndex,
                amount: params.amount,
                amountAll: params.amountAll,
                liquidation: false,
                swapParams: params.swapParams,
                stakeTokenPrice: params.stakeTokenPrice,
                destination: positions[params.positionIndex].owner
            });
    }

    function _withdraw(
        uint positionIndex,
        uint amount,
        bool amountAll,
        bool liquidation,
        SwapLib.SwapParams memory swapParams,
        uint stakeTokenPrice,
        address destination
    ) private {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        Position storage position = positions[positionIndex];
        bool closed = minimaxBase.withdraw(positionIndex, amount, amountAll);

        if (closed) {
            gasTankTreasury.withdrawAll(positionIndex, payable(destination));

            if (liquidation) {
                emitPositionWasLiquidated(positionIndex, basePosition.stakeToken, stakeTokenPrice);
            } else {
                emitPositionWasClosed(positionIndex, basePosition.stakeToken, stakeTokenPrice);
            }
        } else {
            emit PositionWasModified(positionIndex);
        }

        uint actualIn;
        uint actualOut;

        if (address(swapParams.tokenOut) == NativeAddress) {
            swapParams.tokenOut = wToken;
            (actualIn, actualOut) = SwapLib.swap(swapParams, market, oneInchRouter);
            wToken.withdraw(actualOut);
            payable(destination).transfer(actualOut);
        } else {
            (actualIn, actualOut) = SwapLib.swap(swapParams, market, oneInchRouter);
            swapParams.tokenOut.transfer(destination, actualOut);
        }

        // if swapParams.amountIn is less than the amount withdrawn from pool transfer the rest as is
        _drainToken(basePosition.stakeToken, destination);
        // transfer rewards as is
        _drainRewardTokens(positionIndex, basePosition, destination);

        emit StakeTokenWithdraw(positionIndex, basePosition.stakeToken, actualIn, swapParams.tokenOut, actualOut);
    }

    struct AlterPositionV2Params {
        uint positionIndex;
        uint amount;
        uint stopLossPrice;
        uint takeProfitPrice;
        uint maxSlippage;
        uint stakeTokenPrice;
    }

    function alterPositionV2(AlterPositionV2Params calldata params)
        external
        nonReentrant
        onlyPositionOwner(params.positionIndex)
    {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(params.positionIndex);
        Position storage position = positions[params.positionIndex];

        position.stopLoss = params.stopLossPrice;
        position.takeProfit = params.takeProfitPrice;
        position.maxSlippage = params.maxSlippage;
        emit PositionWasModified(params.positionIndex);

        int amountDelta = int(basePosition.stakeAmount) - int(params.amount);
        if (amountDelta > 0) {
            uint withdrawAmount = uint(amountDelta);
            _withdraw({
                positionIndex: params.positionIndex,
                amount: withdrawAmount,
                amountAll: false,
                liquidation: false,
                swapParams: SwapLib.SwapParams({
                    tokenIn: basePosition.stakeToken,
                    amountIn: withdrawAmount,
                    tokenOut: basePosition.stakeToken,
                    amountOutMin: 0,
                    swapKind: SwapLib.SwapNoSwapKind,
                    swapArgs: ""
                }),
                stakeTokenPrice: params.stakeTokenPrice,
                destination: position.owner
            });

            return;
        }

        if (amountDelta < 0) {
            uint depositAmount = uint(-amountDelta);
            _deposit(params.positionIndex, depositAmount);
        }
    }

    function _drainToken(IToken token, address destination) private {
        token.transfer(destination, token.balanceOf(address(this)));
    }

    function _drainRewardTokens(
        uint positionIndex,
        MinimaxBase.Position memory basePosition,
        address destination
    ) private {
        // Transfer rewards as is
        for (uint i = 0; i < basePosition.rewardTokens.length; i++) {
            IToken token = basePosition.rewardTokens[i];
            uint amount = token.balanceOf(address(this));
            token.transfer(destination, amount);
            emit RewardTokenWithdraw(positionIndex, token, amount, token, amount);
        }
    }

    // Gelato

    struct AutomationParams {
        uint256 positionIndex;
        uint256 minAmountOut;
        bytes marketHints;
        uint256 stakeTokenPrice;
    }

    function automationResolveRevert(uint positionIndex) external {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        if (!basePosition.open) {
            RevertLib.revertBytes("");
        }

        (uint amountIn, uint amountOut, bytes memory hints) = _estimateLiquidation(positionIndex, basePosition);
        Position storage position = positions[positionIndex];
        bool canExec = _canLiquidate(positionIndex, basePosition, position, amountIn, amountOut);
        if (!canExec) {
            RevertLib.revertBytes("");
        }

        uint minAmountOut = amountOut - (amountOut * position.maxSlippage) / SLIPPAGE_MULTIPLIER;
        uint stakeTokenPrice = tokenPrice(basePosition.stakeToken);
        AutomationParams memory params = AutomationParams({
            positionIndex: positionIndex,
            minAmountOut: minAmountOut,
            marketHints: hints,
            stakeTokenPrice: stakeTokenPrice
        });
        RevertLib.revertBytes(abi.encodeWithSelector(this.automationExec.selector, abi.encode(params)));
    }

    function automationResolve(uint positionIndex) external returns (bool canExec, bytes memory execPayload) {
        try this.automationResolveRevert(positionIndex) {} catch (bytes memory revertData) {
            return (revertData.length > 0, revertData);
        }
    }

    function automationExec(bytes calldata raw) public nonReentrant onlyAutomator {
        AutomationParams memory params = abi.decode(raw, (AutomationParams));
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(params.positionIndex);
        Position storage position = positions[params.positionIndex];
        _gelatoPayFee(params.positionIndex);

        _withdraw({
            positionIndex: params.positionIndex,
            amount: 0,
            amountAll: true,
            liquidation: true,
            swapParams: SwapLib.SwapParams({
                tokenIn: basePosition.stakeToken,
                amountIn: MAX_INT,
                tokenOut: stableToken,
                amountOutMin: params.minAmountOut,
                swapKind: SwapLib.SwapMarketKind,
                swapArgs: abi.encode(SwapLib.SwapMarket(params.marketHints))
            }),
            stakeTokenPrice: params.stakeTokenPrice,
            destination: position.owner
        });
    }

    function _gelatoPayFee(uint positionIndex) private {
        uint feeAmount;
        address feeDestination;

        if (address(gelatoOps) != address(0)) {
            address feeToken;
            (feeAmount, feeToken) = gelatoOps.getFeeDetails();
            if (feeAmount == 0) {
                return;
            }

            require(feeToken == NativeAddress);
            feeDestination = gelatoOps.gelato();
        } else {
            feeAmount = gasTankThreshold;
            feeDestination = msg.sender;
        }

        gasTankTreasury.withdraw(positionIndex, payable(feeDestination), feeAmount);
    }

    function _gelatoCreateTask(uint positionIndex) private returns (bytes32) {
        if (address(gelatoOps) == address(0)) {
            return 0;
        }

        return
            gelatoOps.createTaskNoPrepayment(
                address(this), /* execAddress */
                this.automationExec.selector, /* execSelector */
                address(this), /* resolverAddress */
                abi.encodeWithSelector(this.automationResolve.selector, positionIndex), /* resolverData */
                NativeAddress
            );
    }

    function _gelatoCancelTask(bytes32 gelatoTaskId) private {
        if (address(gelatoOps) != address(0) && uint(gelatoTaskId) != 0) {
            gelatoOps.cancelTask(gelatoTaskId);
        }
    }

    function _estimateLiquidation(uint positionIndex, MinimaxBase.Position memory basePosition)
        private
        returns (
            uint amountIn,
            uint256 amountOut,
            bytes memory hints
        )
    {
        MinimaxBase.PositionBalance memory balance = minimaxBase.getBalance(positionIndex);
        amountIn = balance.poolStakeAmount;
        (amountOut, hints) = market.estimateOut(address(basePosition.stakeToken), address(stableToken), amountIn);
    }

    function _canLiquidate(
        uint positionIndex,
        MinimaxBase.Position memory basePosition,
        Position storage position,
        uint256 amountIn,
        uint256 amountOut
    ) private returns (bool) {
        uint8 outDecimals = stableToken.decimals();
        uint8 inDecimals = basePosition.stakeToken.decimals();
        bool isOutside = PriceLimitLib.isPriceOutsideLimit({
            priceNumerator: amountOut,
            priceDenominator: amountIn,
            numeratorDecimals: outDecimals,
            denominatorDecimals: inDecimals,
            lowerLimit: position.stopLoss,
            upperLimit: position.takeProfit
        });

        if (isOutside) {
            // double check using oracle
            IPriceOracle oracle = priceOracles[basePosition.stakeToken];
            if (address(oracle) != address(0)) {
                return _isPriceOracleOutsideRange(oracle, position);
            }
        }

        return isOutside;
    }

    function _isPriceOracleOutsideRange(IPriceOracle oracle, Position storage position) private view returns (bool) {
        uint oracleMultiplier = 10**oracle.decimals();
        uint oraclePrice = uint(oracle.latestAnswer());
        return
            PriceLimitLib.isPriceOutsideLimit({
                priceNumerator: oraclePrice,
                priceDenominator: oracleMultiplier,
                numeratorDecimals: 0,
                denominatorDecimals: 0,
                lowerLimit: position.stopLoss,
                upperLimit: position.takeProfit
            });
    }

    // event functions

    function emitPositionWasClosed(
        uint positionIndex,
        IToken token,
        uint tokenPrice
    ) private {
        emit PositionWasClosedV2(positionIndex, block.timestamp, tokenPrice, token.decimals());
    }

    function emitPositionWasLiquidated(
        uint positionIndex,
        IToken token,
        uint tokenPrice
    ) private {
        emit PositionWasLiquidatedV2(positionIndex, block.timestamp, tokenPrice, token.decimals());
    }

    // functions for backward compatibility

    struct PositionInfoCompatible {
        uint stakedAmount; // wei
        uint feeAmount; // FEE_MULTIPLIER
        uint stopLossPrice; // POSITION_PRICE_LIMITS_MULTIPLIER
        uint maxSlippage; // SLIPPAGE_MULTIPLIER
        address poolAddress;
        address owner;
        ProxyCaller callerAddress;
        bool closed;
        uint takeProfitPrice; // POSITION_PRICE_LIMITS_MULTIPLIER
        IERC20Upgradeable stakedToken;
        IERC20Upgradeable rewardToken;
        bytes32 gelatoLiquidateTaskId;
    }

    function getPositionInfo(uint positionIndex) external view returns (PositionInfoCompatible memory) {
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        Position memory position = positions[positionIndex];

        IERC20Upgradeable rewardToken;
        if (basePosition.rewardTokens.length > 0) {
            rewardToken = basePosition.rewardTokens[0];
        } else {
            rewardToken = basePosition.stakeToken;
        }

        return
            PositionInfoCompatible({
                stakedAmount: basePosition.stakeAmount,
                feeAmount: basePosition.feeAmount,
                stopLossPrice: position.stopLoss,
                maxSlippage: position.maxSlippage,
                poolAddress: basePosition.pool,
                owner: position.owner,
                callerAddress: basePosition.proxy,
                closed: !basePosition.open,
                takeProfitPrice: position.takeProfit,
                stakedToken: basePosition.stakeToken,
                rewardToken: rewardToken,
                gelatoLiquidateTaskId: position.gelatoTaskId
            });
    }

    struct PositionBalanceV1 {
        uint total;
        uint reward;
        uint gasTank;
    }

    struct PositionBalanceV2 {
        uint gasTank;
        uint stakedAmount;
        uint poolStakedAmount;
        uint poolRewardAmount;
    }

    struct PositionBalanceV3 {
        uint gasTank;
        uint stakedAmount;
        uint poolStakedAmount;
        uint[] poolRewardAmounts;
    }

    function getPositionBalances(uint[] calldata positionIndexes) public returns (PositionBalanceV1[] memory) {
        PositionBalanceV1[] memory balances = new PositionBalanceV1[](positionIndexes.length);
        for (uint i = 0; i < positionIndexes.length; ++i) {
            try this.getBalanceV1Revert(positionIndexes[i]) {} catch (bytes memory revertData) {
                balances[i] = abi.decode(revertData, (PositionBalanceV1));
            }
        }
        return balances;
    }

    function getPositionBalancesV2(uint[] calldata positionIndexes) public returns (PositionBalanceV2[] memory) {
        PositionBalanceV2[] memory balances = new PositionBalanceV2[](positionIndexes.length);
        for (uint i = 0; i < positionIndexes.length; ++i) {
            try this.getBalanceV2Revert(positionIndexes[i]) {} catch (bytes memory revertData) {
                balances[i] = abi.decode(revertData, (PositionBalanceV2));
            }
        }
        return balances;
    }

    function getPositionBalancesV3(uint[] calldata positionIndexes) public returns (PositionBalanceV3[] memory) {
        PositionBalanceV3[] memory balances = new PositionBalanceV3[](positionIndexes.length);
        for (uint i = 0; i < positionIndexes.length; ++i) {
            try this.getBalanceV3Revert(positionIndexes[i]) {} catch (bytes memory revertData) {
                balances[i] = abi.decode(revertData, (PositionBalanceV3));
            }
        }
        return balances;
    }

    function getBalanceV1Revert(uint positionIndex) external {
        PositionBalanceV1 memory balance;

        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        if (basePosition.open) {
            Position storage position = positions[positionIndex];
            MinimaxBase.PositionBalance memory baseBalance = minimaxBase.getBalance(positionIndex);

            balance.gasTank = gasTankTreasury.balances(positionIndex);

            uint stakingBalance = baseBalance.poolStakeAmount;
            uint rewardBalance = baseBalance.poolRewardAmounts.length > 0 ? baseBalance.poolRewardAmounts[0] : 0;

            if (basePosition.rewardTokens.length == 0 || basePosition.stakeToken == basePosition.rewardTokens[0]) {
                uint totalBalance = rewardBalance + stakingBalance;
                balance.total = totalBalance;
                if (totalBalance > baseBalance.stakeAmount) {
                    balance.reward = totalBalance - baseBalance.stakeAmount;
                }
            } else {
                balance.total = baseBalance.stakeAmount;
                balance.reward = rewardBalance;
            }
        }

        RevertLib.revertBytes(abi.encode(balance));
    }

    function getBalanceV2Revert(uint positionIndex) external {
        PositionBalanceV2 memory balance;
        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        if (basePosition.open) {
            Position storage position = positions[positionIndex];
            MinimaxBase.PositionBalance memory baseBalance = minimaxBase.getBalance(positionIndex);
            balance.gasTank = gasTankTreasury.balances(positionIndex);
            balance.stakedAmount = baseBalance.stakeAmount;
            balance.poolStakedAmount = baseBalance.poolStakeAmount;
            balance.poolRewardAmount = baseBalance.poolRewardAmounts.length > 0 ? baseBalance.poolRewardAmounts[0] : 0;
        }

        RevertLib.revertBytes(abi.encode(balance));
    }

    function getBalanceV3Revert(uint positionIndex) external {
        PositionBalanceV3 memory balance;

        MinimaxBase.Position memory basePosition = minimaxBase.getPosition(positionIndex);
        if (basePosition.open) {
            Position storage position = positions[positionIndex];
            MinimaxBase.PositionBalance memory baseBalance = minimaxBase.getBalance(positionIndex);
            balance.gasTank = gasTankTreasury.balances(positionIndex);
            balance.stakedAmount = baseBalance.stakeAmount;
            balance.poolStakedAmount = baseBalance.poolStakeAmount;
            balance.poolRewardAmounts = baseBalance.poolRewardAmounts;
        }

        RevertLib.revertBytes(abi.encode(balance));
    }
}