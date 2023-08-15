// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/IPendleData.sol";
import "../../interfaces/IPendleMarket.sol";
import "../../interfaces/IPendleForge.sol";
import "../../interfaces/IPendleMarketFactory.sol";
import "../../interfaces/IPendleYieldToken.sol";
import "../../interfaces/IPendlePausingManager.sol";
import "../../periphery/WithdrawableV2.sol";
import "../../tokens/PendleBaseToken.sol";
import "../../libraries/MarketMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
@dev HIGH LEVEL PRINCIPAL:
* So most of the functions in market is only callable by Router, except view/pure functions.
    If a function is non view/pure and is callable by anyone, it must be explicitly stated so
* Market will not do any yieldToken/baseToken transfer but instead will fill in the transfer array
    and router will do them instead. (This is to reduce the number of approval users need to do)
* mint, burn will be done directly with users
*/
abstract contract PendleMarketBase is IPendleMarket, PendleBaseToken, WithdrawableV2 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public immutable override factoryId;
    address internal immutable forge;
    address public immutable override token;
    address public immutable override xyt;
    bool public bootstrapped;

    string private constant NAME = "Pendle Market";
    string private constant SYMBOL = "PENDLE-LPT";
    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    uint8 private constant DECIMALS = 18;
    uint256 private constant LN_PI_PLUSONE = 1562071538258; // this is equal to Math.ln(Math.PI_PLUSONE,Math.RONE)
    uint256 internal constant MULTIPLIER = 10**20;

    // variables for LP interests calc
    uint256 public paramL;
    uint256 public lastNYield;
    mapping(address => uint256) internal lastParamL;
    mapping(address => uint256) internal dueInterests;

    // paramK used for mintProtocolFee. ParamK = xytBal ^ xytWeight * tokenBal ^ tokenW
    uint256 public lastParamK;

    // the last block that we do curveShift
    uint256 public lastCurveShiftBlock;

    /*
    * The reserveData will consist of 3 variables: xytBalance, tokenBalance & xytWeight
    To save gas, we will pack these 3 variables into a single uint256 variable as follows:
        Bit 148 -> 255: xytBalance
        Bit 40 -> 147: tokenBalance
        Bit 0 -> 39: xytWeight
        tokenWeight = Math.RONE - xytWeight
    Refer to writeReserveData and readReserveData for more details
    */
    uint256 private reserveData;
    uint256 private lastRelativePrice = Math.RONE;

    uint256 private constant MASK_148_TO_255 = type(uint256).max ^ ((1 << 148) - 1);
    uint256 private constant MASK_40_TO_147 = ((1 << 148) - 1) ^ ((1 << 40) - 1);
    uint256 private constant MASK_0_TO_39 = ((1 << 40) - 1);
    uint256 private constant MAX_TOKEN_RESERVE_BALANCE = (1 << 108) - 1;

    /*
    * the lockStartTime is set at the bootstrap time of the market, and will not be changed for the entire market duration
    Once the market has been locked, only removeMarketLiquidityDual is allowed
    * Why lock the market? Because when the time is very close to the end of the market, the ratio of weights are either
    extremely big or small, which leads to high precision error
    */
    uint256 public lockStartTime;

    /* these variables are used often, so we get them once in the constructor
    and save gas for retrieving them afterwards */
    bytes32 private immutable forgeId;
    address internal immutable underlyingAsset;
    IERC20 private immutable underlyingYieldToken;
    IPendleData private immutable data;
    IPendlePausingManager private immutable pausingManager;
    uint256 private immutable xytStartTime;

    constructor(
        address _governanceManager,
        address _xyt,
        address _token
    )
        PendleBaseToken(
            address(IPendleYieldToken(_xyt).forge().router()),
            NAME,
            SYMBOL,
            DECIMALS,
            block.timestamp,
            IPendleYieldToken(_xyt).expiry()
        )
        PermissionsV2(_governanceManager)
    {
        require(_xyt != address(0), "ZERO_ADDRESS");
        require(_token != address(0), "ZERO_ADDRESS");
        require(_token != IPendleYieldToken(_xyt).underlyingYieldToken(), "INVALID_TOKEN_PAIR");

        IPendleForge _forge = IPendleYieldToken(_xyt).forge();

        forge = address(_forge);
        xyt = _xyt;
        token = _token;

        forgeId = _forge.forgeId();
        underlyingAsset = IPendleYieldToken(_xyt).underlyingAsset();
        underlyingYieldToken = IERC20(IPendleYieldToken(_xyt).underlyingYieldToken());
        data = _forge.data();
        pausingManager = _forge.data().pausingManager();
        xytStartTime = IPendleYieldToken(_xyt).start();
        factoryId = IPendleMarketFactory(msg.sender).marketFactoryId();

        address _router = address(_forge.router());
        IERC20(_xyt).safeApprove(_router, type(uint256).max);
        IERC20(_token).safeApprove(_router, type(uint256).max);
    }

    // INVARIANT: All write functions, except for ERC20's approve(), increaseAllowance(), decreaseAllowance()
    // must go through this check. This means that minting/burning/transferring of LP tokens is paused too.
    function checkNotPaused() internal {
        (bool paused, ) = pausingManager.checkMarketStatus(factoryId, address(this));
        require(!paused, "MARKET_PAUSED");
    }

    /// Refer to the docs for reserveData
    function readReserveData()
        internal
        view
        returns (
            uint256 xytBalance,
            uint256 tokenBalance,
            uint256 xytWeight,
            uint256 tokenWeight
        )
    {
        xytBalance = (reserveData & MASK_148_TO_255) >> 148;
        tokenBalance = (reserveData & MASK_40_TO_147) >> 40;
        xytWeight = reserveData & MASK_0_TO_39;
        tokenWeight = Math.RONE - xytWeight;
    }

    /// parse an asset address to tokenReserve
    /// _asset will only be either xyt or baseToken
    function parseTokenReserveData(address _asset)
        internal
        view
        returns (TokenReserve memory tokenReserve)
    {
        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, uint256 tokenWeight) =
            readReserveData();
        if (_asset == xyt) {
            tokenReserve = TokenReserve(xytWeight, xytBalance);
        } else {
            tokenReserve = TokenReserve(tokenWeight, tokenBalance);
        }
    }

    /// pass in a tokenReserve & the type of token (through _asset), update the reserveData
    function updateReserveData(TokenReserve memory tokenReserve, address _asset) internal {
        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, uint256 tokenWeight) =
            readReserveData();
        // Basically just update the weight & bal of the corresponding token & write the reserveData again
        if (_asset == xyt) {
            (xytWeight, xytBalance) = (tokenReserve.weight, tokenReserve.balance);
        } else {
            (tokenWeight, tokenBalance) = (tokenReserve.weight, tokenReserve.balance);
            xytWeight = Math.RONE.sub(tokenWeight);
        }
        writeReserveData(xytBalance, tokenBalance, xytWeight);
    }

    /// Refer to the docs for reserveData
    function writeReserveData(
        uint256 xytBalance,
        uint256 tokenBalance,
        uint256 xytWeight
    ) internal {
        require(0 < xytBalance && xytBalance <= MAX_TOKEN_RESERVE_BALANCE, "YT_BALANCE_ERROR");
        require(
            0 < tokenBalance && tokenBalance <= MAX_TOKEN_RESERVE_BALANCE,
            "TOKEN_BALANCE_ERROR"
        );
        reserveData = (xytBalance << 148) | (tokenBalance << 40) | xytWeight;
    }

    // Only the marketEmergencyHandler can call this function, when its in emergencyMode
    // this will allow a spender to spend the whole balance of the specified tokens
    // the spender should ideally be a contract with logic for users to withdraw out their funds.
    function setUpEmergencyMode(address spender) external override {
        (, bool emergencyMode) = pausingManager.checkMarketStatus(factoryId, address(this));
        require(emergencyMode, "NOT_EMERGENCY");
        (address marketEmergencyHandler, , ) = pausingManager.marketEmergencyHandler();
        require(msg.sender == marketEmergencyHandler, "NOT_EMERGENCY_HANDLER");
        IERC20(xyt).safeApprove(spender, type(uint256).max);
        IERC20(token).safeApprove(spender, type(uint256).max);
        IERC20(underlyingYieldToken).safeApprove(spender, type(uint256).max);
    }

    function bootstrap(
        address user,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external override returns (PendingTransfer[2] memory transfers, uint256 exactOutLp) {
        require(msg.sender == address(router), "ONLY_ROUTER");
        checkNotPaused();
        require(!bootstrapped, "ALREADY_BOOTSTRAPPED");

        // market's lock params should be initialized at bootstrap time
        _initializeLock();

        // at the start of the market, xytWeight = tokenWeight = Math.RONE / 2
        // As such, we will write it into the reserveData
        writeReserveData(initialXytLiquidity, initialTokenLiquidity, Math.RONE / 2);
        _updateLastParamK(); // update paramK since this is the first time it's set

        emit Sync(initialXytLiquidity, Math.RONE / 2, initialTokenLiquidity);

        _afterBootstrap();
        // Taking inspiration from Uniswap, we will keep MINIMUM_LIQUIDITY in the market to make sure the market is always non-empty
        exactOutLp = Math.sqrt(initialXytLiquidity.mul(initialTokenLiquidity)).sub(
            MINIMUM_LIQUIDITY
        );

        // No one should possibly own a specific address like this 0x1
        // We mint to 0x1 instead of 0x0 because sending to 0x0 is not permitted
        _mint(address(0x1), MINIMUM_LIQUIDITY);
        _mint(user, exactOutLp);

        transfers[0].amount = initialXytLiquidity;
        transfers[0].isOut = false;
        transfers[1].amount = initialTokenLiquidity;
        transfers[1].isOut = false;

        lastCurveShiftBlock = block.number;
        bootstrapped = true;
    }

    /**
    * @notice Join the market by specifying the desired (and max) amount of xyts
    *    and tokens to put in.
    * @param _desiredXytAmount amount of XYTs user wants to contribute
    * @param _desiredTokenAmount amount of tokens user wants to contribute
    * @param _xytMinAmount min amount of XYTs user wants to be able to contribute
    * @param _tokenMinAmount min amount of tokens user wants to be able to contribute
    * @dev no curveShift to save gas because this function
              doesn't depend on weights of tokens
    * Note: the logic of this function is similar to that of Uniswap
    * Conditions:
        * checkAddRemoveSwapClaimAllowed(false) is true
    */
    function addMarketLiquidityDual(
        address user,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    ) external override returns (PendingTransfer[2] memory transfers, uint256 lpOut) {
        checkAddRemoveSwapClaimAllowed(false);

        // mint protocol fees before k is changed by a non-swap event (add liquidity)
        _mintProtocolFees();

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData();

        uint256 amountXytUsed;
        uint256 amountTokenUsed = _desiredXytAmount.mul(tokenBalance).div(xytBalance);
        if (amountTokenUsed <= _desiredTokenAmount) {
            // using _desiredXytAmount to determine the LP and add liquidity
            require(amountTokenUsed >= _tokenMinAmount, "INSUFFICIENT_TOKEN_AMOUNT");
            amountXytUsed = _desiredXytAmount;
            lpOut = _desiredXytAmount.mul(totalSupply()).div(xytBalance);
        } else {
            // using _desiredTokenAmount to determine the LP and add liquidity
            amountXytUsed = _desiredTokenAmount.mul(xytBalance).div(tokenBalance);
            require(amountXytUsed >= _xytMinAmount, "INSUFFICIENT_YT_AMOUNT");
            amountTokenUsed = _desiredTokenAmount;
            lpOut = _desiredTokenAmount.mul(totalSupply()).div(tokenBalance);
        }

        xytBalance = xytBalance.add(amountXytUsed);
        transfers[0].amount = amountXytUsed;
        transfers[0].isOut = false;

        tokenBalance = tokenBalance.add(amountTokenUsed);
        transfers[1].amount = amountTokenUsed;
        transfers[1].isOut = false;

        writeReserveData(xytBalance, tokenBalance, xytWeight);
        _updateLastParamK(); // update paramK since it has changed due to a non-swap event

        // Mint LP directly to the user
        _mint(user, lpOut);

        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice Join the market by deposit token (single) and get liquidity token
     *       need to specify the desired amount of contributed token (xyt or token)
     *       and minimum output liquidity token
     * @param _inToken address of token (xyt or token) user wants to contribute
     * @param _exactIn amount of tokens (xyt or token)  user wants to contribute
     * @param _minOutLp min amount of liquidity token user expect to receive
     * @dev curveShift needed since function operation relies on weights
     */
    function addMarketLiquiditySingle(
        address user,
        address _inToken,
        uint256 _exactIn,
        uint256 _minOutLp
    ) external override returns (PendingTransfer[2] memory transfers, uint256 exactOutLp) {
        checkAddRemoveSwapClaimAllowed(false);

        // mint protocol fees before k is changed by a non-swap event (add liquidity)
        _mintProtocolFees();
        _curveShift();

        /*
        * Note that in theory we could do another _mintProtocolFee in this function
            to take a portion of the swap fees for the implicit swap of this operation
        * However, we have decided to not charge the protocol fees on the swap fees for this
            operation.
        * The user will still pay the swap fees, just that all the swap fees in the implicit swap
            will all go back to the market (and shared among the LP holders)
        */
        TokenReserve memory inTokenReserve = parseTokenReserveData(_inToken);

        uint256 totalLp = totalSupply();

        // Calc out amount of LP token.
        exactOutLp = MarketMath._calcOutAmountLp(
            _exactIn,
            inTokenReserve,
            data.swapFee(),
            totalLp
        );
        require(exactOutLp >= _minOutLp, "HIGH_LP_OUT_LIMIT");

        // Update reserves and operate underlying LP and inToken.
        inTokenReserve.balance = inTokenReserve.balance.add(_exactIn);
        transfers[0].amount = _exactIn;
        transfers[0].isOut = false;

        // repack data
        updateReserveData(inTokenReserve, _inToken);
        _updateLastParamK(); // update paramK since it has changed not due to swap

        // Mint and push LP token.
        _mint(user, exactOutLp);

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice Exit the market by putting in the desired amount of LP tokens
     *         and getting back XYT and pair tokens.
     * @dev no curveShift to save gas because this function
                doesn't depend on weights of tokens
     * @dev this function will never be locked since we always let users withdraw
                their funds. That's why we skip time check in checkAddRemoveSwapClaimAllowed
     */
    function removeMarketLiquidityDual(
        address user,
        uint256 _inLp,
        uint256 _minOutXyt,
        uint256 _minOutToken
    ) external override returns (PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(true);

        // mint protocol fees before k is changed by a non-swap event (remove liquidity)
        _mintProtocolFees();

        uint256 totalLp = totalSupply();

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data

        // Calc and withdraw xyt token.
        uint256 xytOut = _inLp.mul(xytBalance).div(totalLp);
        uint256 tokenOut = _inLp.mul(tokenBalance).div(totalLp);

        require(tokenOut >= _minOutToken, "INSUFFICIENT_TOKEN_OUT");
        require(xytOut >= _minOutXyt, "INSUFFICIENT_YT_OUT");

        xytBalance = xytBalance.sub(xytOut);
        tokenBalance = tokenBalance.sub(tokenOut);

        transfers[0].amount = xytOut;
        transfers[0].isOut = true;

        transfers[1].amount = tokenOut;
        transfers[1].isOut = true;

        writeReserveData(xytBalance, tokenBalance, xytWeight); // repack data
        _updateLastParamK(); // update paramK since it has changed due to a non-swap event

        _burn(user, _inLp);

        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice Exit the market by putting in the desired amount of LP tokens
     *      and getting back XYT or pair tokens.
     * @param _outToken address of the token that user wants to get back
     * @param _inLp the exact amount of liquidity token that user wants to put back
     * @param _minOutAmountToken the minimum of token that user wants to get back
     * @dev curveShift needed since function operation relies on weights
     */
    function removeMarketLiquiditySingle(
        address user,
        address _outToken,
        uint256 _inLp,
        uint256 _minOutAmountToken
    ) external override returns (PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(false);

        // mint protocol fees before k is changed by a non-swap event (remove liquidity)
        _mintProtocolFees();
        _curveShift();

        /*
        * Note that in theory we should do another _mintProtocolFee in this function
            since this add single involves an implicit swap operation
        * The reason we don't do that is same as in addMarketLiquiditySingle
        */
        TokenReserve memory outTokenReserve = parseTokenReserveData(_outToken);

        uint256 swapFee = data.swapFee();
        uint256 totalLp = totalSupply();

        uint256 outAmountToken =
            MarketMath._calcOutAmountToken(outTokenReserve, totalLp, _inLp, swapFee);
        require(outAmountToken >= _minOutAmountToken, "INSUFFICIENT_TOKEN_OUT");

        outTokenReserve.balance = outTokenReserve.balance.sub(outAmountToken);
        transfers[0].amount = outAmountToken;
        transfers[0].isOut = true;

        updateReserveData(outTokenReserve, _outToken);
        _updateLastParamK(); // update paramK since it has changed by a non-swap event

        _burn(user, _inLp);

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    function swapExactIn(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 minOutAmount
    ) external override returns (uint256 outAmount, PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(false);

        // We only need to do _mintProtocolFees if there is a curveShift that follows
        if (checkNeedCurveShift()) {
            _mintProtocolFees();
            _curveShift();
            _updateLastParamK(); // update paramK since it has changed due to a non-swap event
        }

        TokenReserve memory inTokenReserve = parseTokenReserveData(inToken);
        TokenReserve memory outTokenReserve = parseTokenReserveData(outToken);

        // calc out amount of token to be swapped out
        outAmount = MarketMath._calcExactOut(
            inTokenReserve,
            outTokenReserve,
            inAmount,
            data.swapFee()
        );
        require(outAmount >= minOutAmount, "HIGH_OUT_LIMIT");

        inTokenReserve.balance = inTokenReserve.balance.add(inAmount);
        outTokenReserve.balance = outTokenReserve.balance.sub(outAmount);

        // repack data
        updateReserveData(inTokenReserve, inToken);
        updateReserveData(outTokenReserve, outToken);
        // no update paramK since it has changed but due to swap

        transfers[0].amount = inAmount;
        transfers[0].isOut = false;
        transfers[1].amount = outAmount;
        transfers[1].isOut = true;

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    function swapExactOut(
        address inToken,
        uint256 maxInAmount,
        address outToken,
        uint256 outAmount
    ) external override returns (uint256 inAmount, PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(false);

        // We only need to do _mintProtocolFees if there is a curveShift that follows
        if (checkNeedCurveShift()) {
            _mintProtocolFees();
            _curveShift();
            _updateLastParamK(); // update paramK since it has changed due to a non-swap event
        }

        TokenReserve memory inTokenReserve = parseTokenReserveData(inToken);
        TokenReserve memory outTokenReserve = parseTokenReserveData(outToken);

        // Calc in amount.
        inAmount = MarketMath._calcExactIn(
            inTokenReserve,
            outTokenReserve,
            outAmount,
            data.swapFee()
        );
        require(inAmount <= maxInAmount, "LOW_IN_LIMIT");

        inTokenReserve.balance = inTokenReserve.balance.add(inAmount);
        outTokenReserve.balance = outTokenReserve.balance.sub(outAmount);

        // repack data
        updateReserveData(inTokenReserve, inToken);
        updateReserveData(outTokenReserve, outToken);
        // no update paramK since it has changed but due to swap

        transfers[0].amount = inAmount;
        transfers[0].isOut = false;
        transfers[1].amount = outAmount;
        transfers[1].isOut = true;

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice for user to claim their interest as holder of underlyingYield token
     * @param user user's address
     * @dev only can claim through router (included in checkAddRemoveSwapClaimAllowed)
     * We skip time check in checkAddRemoveSwapClaimAllowed because users can always claim interests
     * Since the Router has already had Reentrancy protection, we don't need one here
     */
    function redeemLpInterests(address user) external override returns (uint256 interests) {
        checkAddRemoveSwapClaimAllowed(true);
        interests = _beforeTransferDueInterests(user);
        _safeTransferYieldToken(user, interests);
    }

    /**
     * @notice get the most up-to-date reserveData of the market by doing a dry curveShift
     */
    function getReserves()
        external
        view
        override
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        )
    {
        (xytBalance, tokenBalance, xytWeight, tokenWeight) = readReserveData();
        if (checkNeedCurveShift()) {
            (xytWeight, tokenWeight, ) = _updateWeightDry();
        }
        currentBlock = block.number;
    }

    /**
     * @notice update the weights of the market
     */
    function _updateWeight() internal {
        (uint256 xytBalance, uint256 tokenBalance, , ) = readReserveData(); // unpack data
        (uint256 xytWeightUpdated, , uint256 currentRelativePrice) = _updateWeightDry();
        writeReserveData(xytBalance, tokenBalance, xytWeightUpdated); // repack data

        lastRelativePrice = currentRelativePrice;
    }

    // do the weight update calculation but don't update the token reserve memory
    function _updateWeightDry()
        internal
        view
        returns (
            uint256 xytWeightUpdated,
            uint256 tokenWeightUpdated,
            uint256 currentRelativePrice
        )
    {
        // get current timestamp currentTime
        uint256 currentTime = block.timestamp;
        uint256 endTime = expiry;
        uint256 startTime = xytStartTime;
        uint256 duration = endTime - startTime;

        (, , uint256 xytWeight, uint256 tokenWeight) = readReserveData(); // unpack data

        uint256 timeLeft;
        if (endTime >= currentTime) {
            timeLeft = endTime - currentTime;
        } else {
            timeLeft = 0;
        }

        // get time_to_mature = (endTime - currentTime) / (endTime - startTime)
        uint256 timeToMature = Math.rdiv(timeLeft * Math.RONE, duration * Math.RONE);

        // get price for now = ln(3.14 * t + 1) / ln(4.14)
        currentRelativePrice = Math.rdiv(
            Math.ln(Math.rmul(Math.PI, timeToMature).add(Math.RONE), Math.RONE),
            LN_PI_PLUSONE
        );

        uint256 r = Math.rdiv(currentRelativePrice, lastRelativePrice);
        require(Math.RONE >= r, "MATH_ERROR");

        uint256 thetaNumerator = Math.rmul(Math.rmul(xytWeight, tokenWeight), Math.RONE.sub(r));
        uint256 thetaDenominator = Math.rmul(r, xytWeight).add(tokenWeight);

        // calc weight changes theta
        uint256 theta = Math.rdiv(thetaNumerator, thetaDenominator);

        xytWeightUpdated = xytWeight.sub(theta);
        tokenWeightUpdated = tokenWeight.add(theta);
    }

    /*
     To add/remove/swap/claim, the market must have been
     * bootstrapped
     * only Router can call it
     * if the function is not removeMarketLiquidityDual, then must check the market hasn't been locked yet
     */
    function checkAddRemoveSwapClaimAllowed(bool skipOpenCheck) internal {
        checkNotPaused();
        require(bootstrapped, "NOT_BOOTSTRAPPED");
        require(msg.sender == address(router), "ONLY_ROUTER");
        if (!skipOpenCheck) {
            require(block.timestamp < lockStartTime, "MARKET_LOCKED");
        }
    }

    //curve shift will be called before any calculation using weight
    //Note: there must be a _mintProtocolFees() before calling _curveShift()
    function _curveShift() internal {
        if (!checkNeedCurveShift()) return;
        _updateWeight();
        lastCurveShiftBlock = block.number;
    }

    /**
    @notice To be called before the dueInterest of any users is redeemed
    */
    function _beforeTransferDueInterests(address user) internal returns (uint256 amountOut) {
        _updateDueInterests(user);

        amountOut = dueInterests[user];
        dueInterests[user] = 0;

        // Use subMax0 to handle the extreme case of the market lacking a few wei of tokens to send out
        lastNYield = lastNYield.subMax0(amountOut);
    }

    /**
     * We will only updateParamL if the normalisedIncome / exchangeRate has increased more than a delta
     * This delta is expected to be very small
     */
    function checkNeedUpdateParamL() internal returns (bool) {
        return _getIncomeIndexIncreaseRate() > data.interestUpdateRateDeltaForMarket();
    }

    /**
     * We will only do curveShift() once every curveShiftBlockDelta blocks
     */
    function checkNeedCurveShift() internal view returns (bool) {
        return block.number > lastCurveShiftBlock.add(data.curveShiftBlockDelta());
    }

    /**
     * @notice use to updateParamL. Must only be called by _updateDueInterests
     * ParamL can be thought of as an always-increase incomeIndex for 1 LP
     Consideration:
     * Theoretically we have to updateParamL whenever the _updateDueInterests is called, since the external incomeIndex
        (normalisedIncome/exchangeRate) is always increasing, and there are always interests to be claimed
     * Yet, if we do so, the amount of interests to be claimed maybe negligible while the amount of gas spent is
        tremendous (100k~200k last time we checked) => Caching is actually beneficial to user
     * The users may lose some negligible amount of interest when they do removeLiquidity or transfer LP to others
        (to be exact, they will lose NO MORE THAN interestUpdateRateDeltaForMarket%). In exchange, they will save
        a lot of gas.
        * If we assume the yearly interest rate is 10%, and we would like to only update the market's interest every one hour,
          interestUpdateRateDeltaForMarket% = 1.10 ^ (1/ (365*24)) - 1 = 0.00108802167011 %
     * The correctness of caching can be thought of like this: We just pretend that there are only income once in a while,
     and when that income come, they will come in large amount, and we will distribute them fairly to all users
     */
    function _updateParamL() internal {
        if (!checkNeedUpdateParamL()) return;
        // redeem the interest from XYT
        router.redeemDueInterests(forgeId, underlyingAsset, expiry, address(this));

        uint256 currentNYield = underlyingYieldToken.balanceOf(address(this));
        (uint256 firstTerm, uint256 paramR) = _getFirstTermAndParamR(currentNYield);
        uint256 secondTerm;

        /*
        * paramR can be thought of as the amount of interest earned by the market
        (but excluding the compound effect). paramR is normally small & totalSupply is
        normally much larger so we need to multiply them with MULTIPLIER
        */
        if (totalSupply() != 0) secondTerm = paramR.mul(MULTIPLIER).div(totalSupply());

        // firstTerm & secondTerm are not the best names, but please refer to AMM specs
        // to understand the meaning of these 2 params
        paramL = firstTerm.add(secondTerm);
        lastNYield = currentNYield;
    }

    // before we send LPs, we need to update LP interests for both the to and from addresses
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        checkNotPaused();
        if (from != address(0)) _updateDueInterests(from);
        if (to != address(0)) _updateDueInterests(to);
    }

    /**
    @dev Must be the only way to transfer aToken/cToken out
    // Please refer to _safeTransfer of PendleForgeBase for the rationale of this function
    */
    function _safeTransferYieldToken(address _user, uint256 _amount) internal {
        if (_amount == 0) return;
        _amount = Math.min(_amount, underlyingYieldToken.balanceOf(address(this)));
        underlyingYieldToken.safeTransfer(_user, _amount);
    }

    /**
     * @notice _initialize the lock of the market. Must only be called in bootstrap
     */
    function _initializeLock() internal {
        uint256 duration = expiry.sub(xytStartTime); // market expiry = xyt expiry
        uint256 lockDuration = duration.mul(data.lockNumerator()).div(data.lockDenominator());
        lockStartTime = expiry.sub(lockDuration);
    }

    /**
    @notice _mint new LP for protocol fee. Mint them directly to the treasury
    @dev this function should be very similar to Uniswap
    */
    function _mintProtocolFees() internal {
        uint256 feeRatio = data.protocolSwapFee();
        uint256 _lastParamK = lastParamK;
        if (feeRatio > 0) {
            if (_lastParamK != 0) {
                uint256 k = _calcParamK();
                if (k > _lastParamK) {
                    uint256 numer = totalSupply().mul(k.sub(_lastParamK));
                    uint256 denom = Math.RONE.sub(feeRatio).mul(k).div(feeRatio).add(_lastParamK);
                    uint256 liquidity = numer / denom;
                    address treasury = data.treasury();
                    if (liquidity > 0) {
                        _mint(treasury, liquidity);
                    }
                }
            }
        } else if (_lastParamK != 0) {
            // if fee is turned off, we need to reset lastParamK as well
            lastParamK = 0;
        }
    }

    /**
    Equation for paramK: paramK = xytBal ^ xytWeight * tokenBal ^ tokenW
    * @dev must be called whenever the above equation changes but not due to a swapping action
    I.e: after add/remove/bootstrap liquidity or curveShift
    */
    function _updateLastParamK() internal {
        if (data.protocolSwapFee() == 0) return;
        lastParamK = _calcParamK();
    }

    /**
     * @notice calc the value of paramK. The formula for this can be referred in the AMM specs
     */
    function _calcParamK() internal view returns (uint256 paramK) {
        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, uint256 tokenWeight) =
            readReserveData();
        paramK = Math
            .rpow(xytBalance.toFP(), xytWeight)
            .rmul(Math.rpow(tokenBalance.toFP(), tokenWeight))
            .toInt();
    }

    function _allowedToWithdraw(address _token) internal view override returns (bool allowed) {
        allowed =
            _token != xyt &&
            _token != token &&
            _token != address(this) &&
            _token != address(underlyingYieldToken);
    }

    function _afterBootstrap() internal virtual;

    /**
    @notice update the LP interest for users (before their balances of LP changes)
    @dev This must be called before any transfer / mint/ burn action of LP
        (and this has been implemented in the beforeTokenTransfer of this contract)
    */
    function _updateDueInterests(address user) internal virtual;

    /// @notice Get params to update paramL. Must only be called by updateParamL
    function _getFirstTermAndParamR(uint256 currentNYield)
        internal
        virtual
        returns (uint256 firstTerm, uint256 paramR);

    /// @notice Get the increase rate of normalisedIncome / exchangeRate
    function _getIncomeIndexIncreaseRate() internal virtual returns (uint256 increaseRate);
}