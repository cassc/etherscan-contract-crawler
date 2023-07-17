// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/MathLib.sol";
import "../interfaces/IPendleRouter.sol";
import "../interfaces/IPendleData.sol";
import "../interfaces/IPendleForge.sol";
import "../interfaces/IPendleMarketFactory.sol";
import "../interfaces/IPendleMarket.sol";
import "../periphery/PermissionsV2.sol";
import "../periphery/WithdrawableV2.sol";
import "../periphery/PendleRouterNonReentrant.sol";

/**
@dev OVERALL NOTE:
* The router will not hold any funds, instead it will just help sending funds to other contracts & users
* addLiquidity/removeLiquidity/swap all supports auto wrap of ETH
    - There will be no markets of XYT-ETH, only markets of XYT-WETH
    - If users want to send in / receive ETH, just pass the ETH_ADDRESS to the corresponding field,
    the router will automatically wrap/unwrap WETH and interact with markets
    - principle of ETH wrap implementation: always use the token with the "original" prefix for transfer,
    and use the non-original token (_xyt, _token...) in all other cases
* Markets will not transfer any XYT/baseToken, but instead make requests to Router through the transfer array
    and the Router will transfer them
*/
contract PendleRouter is IPendleRouter, WithdrawableV2, PendleRouterNonReentrant {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Math for uint256;

    IWETH public immutable override weth;
    IPendleData public immutable override data;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    // if someone's allowance for the router is below this amount,
    // we will approve the router again (to spend from their account)
    // if we already call .approveRouter for the a token, we shouldn't need to approve again
    uint256 private constant REASONABLE_ALLOWANCE_AMOUNT = type(uint256).max / 2;

    constructor(
        address _governanceManager,
        IWETH _weth,
        IPendleData _data
    ) PermissionsV2(_governanceManager) PendleRouterNonReentrant() {
        weth = _weth;
        data = _data;
    }

    /**
     * @dev Accepts ETH via fallback from the WETH contract.
     **/
    receive() external payable {
        require(msg.sender == address(weth), "ETH_NOT_FROM_WETH");
    }

    /**
     * @notice Create a new pair of OT + XYT tokens to represent the
     *   principal and interest for an underlying asset, until an expiry
     Conditions:
     * _expiry must be divisible for expiryDivisor() so that there are not too many yieldContracts
     * Any _underlyingAsset can be passed in, since there is no way to validate them
     * Have Reentrancy protection
     **/
    function newYieldContracts(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry
    ) external override nonReentrant returns (address ot, address xyt) {
        require(_underlyingAsset != address(0), "ZERO_ADDRESS");
        require(_expiry > block.timestamp, "INVALID_EXPIRY");
        require(_expiry % data.expiryDivisor() == 0, "INVALID_EXPIRY");
        IPendleForge forge = IPendleForge(data.getForgeAddress(_forgeId));
        require(address(forge) != address(0), "FORGE_NOT_EXISTS");

        ot = address(data.otTokens(_forgeId, _underlyingAsset, _expiry));
        xyt = address(data.xytTokens(_forgeId, _underlyingAsset, _expiry));
        require(ot == address(0) && xyt == address(0), "DUPLICATE_YIELD_CONTRACT");

        (ot, xyt) = forge.newYieldContracts(_underlyingAsset, _expiry);
    }

    /**
     * @notice After an expiry, redeem OT tokens to get back the underlyingYieldToken
     *         and also any interests
     * @notice This function acts as a proxy to the actual function
     * @dev The interest from "the last global action before expiry" until the expiry
     *      is given to the OT holders. This is to simplify accounting. An assumption
     *      is that the last global action before expiry will be close to the expiry
     * @dev all validity checks are in the internal function
    Conditions:
     * Have Reentrancy protection
     **/
    function redeemAfterExpiry(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry
    ) public override nonReentrant returns (uint256 redeemedAmount) {
        require(data.isValidXYT(_forgeId, _underlyingAsset, _expiry), "INVALID_YT");
        require(_expiry < block.timestamp, "MUST_BE_AFTER_EXPIRY");

        // guaranteed to be a valid forge by the isValidXYT check
        IPendleForge forge = IPendleForge(data.getForgeAddress(_forgeId));

        redeemedAmount = forge.redeemAfterExpiry(msg.sender, _underlyingAsset, _expiry);
    }

    /**
     * @notice redeem the dueInterests from XYTs
     * @dev all validity checks are in the internal function
     Conditions:
     * Have Reentrancy protection
     **/
    function redeemDueInterests(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external override nonReentrant returns (uint256 interests) {
        require(data.isValidXYT(_forgeId, _underlyingAsset, _expiry), "INVALID_YT");
        require(_user != address(0), "ZERO_ADDRESS");
        IPendleForge forge = IPendleForge(data.getForgeAddress(_forgeId));
        interests = forge.redeemDueInterests(_user, _underlyingAsset, _expiry);
    }

    /**
     * @notice Before the expiry, a user can redeem the same amount of OT+XYT to get back
     *       the underlying yield token
     Conditions:
     * Have Reentrancy protection
     **/
    function redeemUnderlying(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        uint256 _amountToRedeem
    ) external override nonReentrant returns (uint256 redeemedAmount) {
        require(data.isValidXYT(_forgeId, _underlyingAsset, _expiry), "INVALID_YT");
        require(block.timestamp < _expiry, "YIELD_CONTRACT_EXPIRED");
        require(_amountToRedeem != 0, "ZERO_AMOUNT");

        // guaranteed to be a valid forge by the isValidXYT check
        IPendleForge forge = IPendleForge(data.getForgeAddress(_forgeId));

        redeemedAmount = forge.redeemUnderlying(
            msg.sender,
            _underlyingAsset,
            _expiry,
            _amountToRedeem
        );
    }

    /**
     * @notice Use to renewYield. Basically a proxy to call redeemAfterExpiry & tokenizeYield
     * @param _renewalRate a Fixed Point number, shows how much of the total redeemedAmount is renewed.
        We allowed _renewalRate > RONE in case the user wants to increase his position
     Conditions:
     * No Reentrancy protection because it will just act as a proxy for 2 calls
     **/
    function renewYield(
        bytes32 _forgeId,
        uint256 _oldExpiry,
        address _underlyingAsset,
        uint256 _newExpiry,
        uint256 _renewalRate
    )
        external
        override
        returns (
            uint256 redeemedAmount,
            uint256 amountRenewed,
            address ot,
            address xyt,
            uint256 amountTokenMinted
        )
    {
        require(0 < _renewalRate, "INVALID_RENEWAL_RATE");
        redeemedAmount = redeemAfterExpiry(_forgeId, _underlyingAsset, _oldExpiry);
        amountRenewed = redeemedAmount.rmul(_renewalRate);
        (ot, xyt, amountTokenMinted) = tokenizeYield(
            _forgeId,
            _underlyingAsset,
            _newExpiry,
            amountRenewed,
            msg.sender
        );
    }

    /**
     * @notice tokenize yield tokens to get OT+XYT. We allows tokenizing for others too
     * @dev each forge is for a yield protocol (for example: Aave, Compound)
    Conditions:
     * Have Reentrancy protection
     * Can only tokenize to a not-yet-expired XYT
     **/
    function tokenizeYield(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        uint256 _amountToTokenize,
        address _to
    )
        public
        override
        nonReentrant
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        )
    {
        require(data.isValidXYT(_forgeId, _underlyingAsset, _expiry), "INVALID_YT");
        require(block.timestamp < _expiry, "YIELD_CONTRACT_EXPIRED");
        require(_to != address(0), "ZERO_ADDRESS");
        require(_amountToTokenize != 0, "ZERO_AMOUNT");

        // guaranteed to be a valid forge by the isValidXYT check
        IPendleForge forge = IPendleForge(data.getForgeAddress(_forgeId));

        // In this getYieldBearingToken call, the forge will check if there is
        // any yieldToken that matches the underlyingAsset. For more details please
        // check the getYieldBearingToken in forge
        IERC20 yieldToken = IERC20(forge.getYieldBearingToken(_underlyingAsset));

        // pull tokens in
        yieldToken.safeTransferFrom(
            msg.sender,
            forge.yieldTokenHolders(_underlyingAsset, _expiry),
            _amountToTokenize
        );

        // mint OT&XYT for users
        (ot, xyt, amountTokenMinted) = forge.mintOtAndXyt(
            _underlyingAsset,
            _expiry,
            _amountToTokenize,
            _to
        );
    }

    /**
     * @notice add market liquidity by both xyt and baseToken
     Conditions:
     * Have Reentrancy protection
     */
    function addMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    )
        public
        payable
        override
        nonReentrant
        returns (
            uint256 amountXytUsed,
            uint256 amountTokenUsed,
            uint256 lpOut
        )
    {
        require(
            _desiredXytAmount != 0 && _desiredXytAmount >= _xytMinAmount,
            "INVALID_YT_AMOUNTS"
        );
        require(
            _desiredTokenAmount != 0 && _desiredTokenAmount >= _tokenMinAmount,
            "INVALID_TOKEN_AMOUNTS"
        );

        address originalToken = _token;
        _token = _isETH(_token) ? address(weth) : _token;

        IPendleMarket market = IPendleMarket(data.getMarket(_marketFactoryId, _xyt, _token));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        // note that LP minting will be done in the market
        PendingTransfer[2] memory transfers;
        (transfers, lpOut) = market.addMarketLiquidityDual(
            msg.sender,
            _desiredXytAmount,
            _desiredTokenAmount,
            _xytMinAmount,
            _tokenMinAmount
        );
        _settlePendingTransfers(transfers, _xyt, originalToken, address(market));

        amountXytUsed = transfers[0].amount;
        amountTokenUsed = transfers[1].amount;
        emit Join(msg.sender, amountXytUsed, amountTokenUsed, address(market), lpOut);
    }

    /**
     * @notice add market liquidity by xyt or base token
     * @dev no checks on _minOutLp
     * @param _forXyt whether the user wants to addLiquidity by _xyt or _token
     Conditions:
     * Have Reentrancy protection
     */
    function addMarketLiquiditySingle(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        bool _forXyt,
        uint256 _exactIn,
        uint256 _minOutLp
    ) external payable override nonReentrant returns (uint256 exactOutLp) {
        require(_exactIn != 0, "ZERO_AMOUNTS");

        address originalToken = _token;
        _token = _isETH(_token) ? address(weth) : _token;

        IPendleMarket market = IPendleMarket(data.getMarket(_marketFactoryId, _xyt, _token));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        address assetToTransferIn = _forXyt ? _xyt : originalToken;
        address assetForMarket = _forXyt ? _xyt : _token;

        // note that LP minting will be done in the market
        PendingTransfer[2] memory transfers;
        (transfers, exactOutLp) = market.addMarketLiquiditySingle(
            msg.sender,
            assetForMarket,
            _exactIn,
            _minOutLp
        );

        if (_forXyt) {
            emit Join(msg.sender, _exactIn, 0, address(market), exactOutLp);
        } else {
            emit Join(msg.sender, 0, _exactIn, address(market), exactOutLp);
        }
        // We only need settle the transfering in of the assetToTransferIn
        _settleTokenTransfer(assetToTransferIn, transfers[0], address(market));
    }

    /**
     * @notice remove market liquidity by xyt and base tokens
     * @dev no checks on _minOutXyt, _minOutToken
     Conditions:
     * Have Reentrancy protection
     */
    function removeMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _exactInLp,
        uint256 _minOutXyt,
        uint256 _minOutToken
    ) external override nonReentrant returns (uint256 exactOutXyt, uint256 exactOutToken) {
        require(_exactInLp != 0, "ZERO_LP_IN");

        address originalToken = _token;
        _token = _isETH(_token) ? address(weth) : _token;

        IPendleMarket market = IPendleMarket(data.getMarket(_marketFactoryId, _xyt, _token));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        // note that LP burning will be done in the market
        PendingTransfer[2] memory transfers =
            market.removeMarketLiquidityDual(msg.sender, _exactInLp, _minOutXyt, _minOutToken);

        _settlePendingTransfers(transfers, _xyt, originalToken, address(market));
        exactOutXyt = transfers[0].amount;
        exactOutToken = transfers[1].amount;
        emit Exit(msg.sender, exactOutXyt, exactOutToken, address(market), _exactInLp);
    }

    /**
     * @notice remove market liquidity by xyt or base tokens
     * @dev no checks on  _minOutAsset
     * @param _forXyt whether the user wants to addLiquidity by _xyt or _token
     Conditions:
     * Have Reentrancy protection
     */
    function removeMarketLiquiditySingle(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        bool _forXyt,
        uint256 _exactInLp,
        uint256 _minOutAsset
    ) external override nonReentrant returns (uint256 exactOutXyt, uint256 exactOutToken) {
        require(_exactInLp != 0, "ZERO_LP_IN");

        address originalToken = _token;
        _token = _isETH(_token) ? address(weth) : _token;

        IPendleMarket market = IPendleMarket(data.getMarket(_marketFactoryId, _xyt, _token));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        address assetForMarket = _forXyt ? _xyt : _token;

        // note that LP burning will be done in the market
        PendingTransfer[2] memory transfers =
            market.removeMarketLiquiditySingle(
                msg.sender,
                assetForMarket,
                _exactInLp,
                _minOutAsset
            );

        address assetToTransferOut = _forXyt ? _xyt : originalToken;
        _settleTokenTransfer(assetToTransferOut, transfers[0], address(market));

        if (_forXyt) {
            emit Exit(msg.sender, transfers[0].amount, 0, address(market), _exactInLp);
            return (transfers[0].amount, 0);
        } else {
            emit Exit(msg.sender, 0, transfers[0].amount, address(market), _exactInLp);
            return (0, transfers[0].amount);
        }
    }

    /**
     * @notice create a new market for a pair of xyt & token
     * @dev A market can be uniquely identified by the triplet(_marketFactoryId,_xyt,_token)
     Conditions:
     * Have Reentrancy protection
     */
    function createMarket(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token
    ) external override nonReentrant returns (address market) {
        require(_xyt != address(0), "ZERO_ADDRESS");
        require(_token != address(0), "ZERO_ADDRESS");
        require(data.isXyt(_xyt), "INVALID_YT");
        require(!data.isXyt(_token), "YT_QUOTE_PAIR_FORBIDDEN");
        require(data.getMarket(_marketFactoryId, _xyt, _token) == address(0), "EXISTED_MARKET");

        IPendleMarketFactory factory =
            IPendleMarketFactory(data.getMarketFactoryAddress(_marketFactoryId));
        require(address(factory) != address(0), "ZERO_ADDRESS");

        bytes32 forgeId = IPendleForge(IPendleYieldToken(_xyt).forge()).forgeId();
        require(data.validForgeFactoryPair(forgeId, _marketFactoryId), "INVALID_FORGE_FACTORY");

        market = factory.createMarket(_xyt, _token);

        emit MarketCreated(_marketFactoryId, _xyt, _token, market);
    }

    /**
     * @notice bootstrap a market (aka the first one to add liquidity)
     Conditions:
     * Have Reentrancy protection
     */
    function bootstrapMarket(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _initialXytLiquidity,
        uint256 _initialTokenLiquidity
    ) external payable override nonReentrant {
        require(_initialXytLiquidity > 0, "INVALID_YT_AMOUNT");
        require(_initialTokenLiquidity > 0, "INVALID_TOKEN_AMOUNT");

        address originalToken = _token;
        _token = _isETH(_token) ? address(weth) : _token;

        IPendleMarket market = IPendleMarket(data.getMarket(_marketFactoryId, _xyt, _token));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        PendingTransfer[2] memory transfers;
        uint256 exactOutLp;
        (transfers, exactOutLp) = market.bootstrap(
            msg.sender,
            _initialXytLiquidity,
            _initialTokenLiquidity
        );

        _settlePendingTransfers(transfers, _xyt, originalToken, address(market));
        emit Join(
            msg.sender,
            _initialXytLiquidity,
            _initialTokenLiquidity,
            address(market),
            exactOutLp
        );
    }

    /**
     * @notice trade by swap exact amount of token into market
     * @dev no checks on _minOutAmount
     Conditions:
     * Have Reentrancy protection
     */
    function swapExactIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _inAmount,
        uint256 _minOutAmount,
        bytes32 _marketFactoryId
    ) external payable override nonReentrant returns (uint256 outSwapAmount) {
        require(_inAmount != 0, "ZERO_IN_AMOUNT");

        address originalTokenIn = _tokenIn;
        address originalTokenOut = _tokenOut;
        _tokenIn = _isETH(_tokenIn) ? address(weth) : _tokenIn;
        _tokenOut = _isETH(_tokenOut) ? address(weth) : _tokenOut;

        IPendleMarket market =
            IPendleMarket(data.getMarketFromKey(_tokenIn, _tokenOut, _marketFactoryId));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        PendingTransfer[2] memory transfers;
        (outSwapAmount, transfers) = market.swapExactIn(
            _tokenIn,
            _inAmount,
            _tokenOut,
            _minOutAmount
        );

        _settlePendingTransfers(transfers, originalTokenIn, originalTokenOut, address(market));

        emit SwapEvent(msg.sender, _tokenIn, _tokenOut, _inAmount, outSwapAmount, address(market));
    }

    /**
     * @notice trade by swap exact amount of token out of market
     * @dev no checks on _maxInAmount
     Conditions:
     * Have Reentrancy protection
     */
    function swapExactOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _outAmount,
        uint256 _maxInAmount,
        bytes32 _marketFactoryId
    ) external payable override nonReentrant returns (uint256 inSwapAmount) {
        require(_outAmount != 0, "ZERO_OUT_AMOUNT");

        address originalTokenIn = _tokenIn;
        address originalTokenOut = _tokenOut;
        _tokenIn = _isETH(_tokenIn) ? address(weth) : _tokenIn;
        _tokenOut = _isETH(_tokenOut) ? address(weth) : _tokenOut;

        IPendleMarket market =
            IPendleMarket(data.getMarketFromKey(_tokenIn, _tokenOut, _marketFactoryId));
        require(address(market) != address(0), "MARKET_NOT_FOUND");

        PendingTransfer[2] memory transfers;
        (inSwapAmount, transfers) = market.swapExactOut(
            _tokenIn,
            _maxInAmount,
            _tokenOut,
            _outAmount
        );

        _settlePendingTransfers(transfers, originalTokenIn, originalTokenOut, address(market));

        emit SwapEvent(msg.sender, _tokenIn, _tokenOut, inSwapAmount, _outAmount, address(market));
    }

    /**
     * @notice For Lp holders to claim Lp interests
    Conditions:
     * Have Reentrancy protection
     */
    function redeemLpInterests(address market, address user)
        external
        override
        nonReentrant
        returns (uint256 interests)
    {
        require(data.isMarket(market), "INVALID_MARKET");
        require(user != address(0), "ZERO_ADDRESS");
        interests = IPendleMarket(market).redeemLpInterests(user);
    }

    function _getData() internal view override returns (IPendleData) {
        return data;
    }

    function _isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }

    /**
     * @notice This function takes in the standard array PendingTransfer[2] that represents
     *        any pending transfers of tokens to be done between a market and msg.sender
     * @dev transfers[0] and transfers[1] always represent the tokens that are traded
     *    The convention is that:
     *      - if its a function with xyt and baseToken, transfers[0] is always xyt
     *      - if its a function with tokenIn and tokenOut, transfers[0] is always tokenOut
     */
    function _settlePendingTransfers(
        PendingTransfer[2] memory transfers,
        address firstToken,
        address secondToken,
        address market
    ) internal {
        _settleTokenTransfer(firstToken, transfers[0], market);
        _settleTokenTransfer(secondToken, transfers[1], market);
    }

    /**
     * @notice This function settles a PendingTransfer, where the token could be ETH_ADDRESS
     *        a PendingTransfer is always between a market and msg.sender
     */
    function _settleTokenTransfer(
        address token,
        PendingTransfer memory transfer,
        address market
    ) internal {
        if (transfer.amount == 0) {
            return;
        }
        if (transfer.isOut) {
            if (_isETH(token)) {
                weth.transferFrom(market, address(this), transfer.amount);
                weth.withdraw(transfer.amount);
                (bool success, ) = msg.sender.call{value: transfer.amount}("");
                require(success, "TRANSFER_FAILED");
            } else {
                IERC20(token).safeTransferFrom(market, msg.sender, transfer.amount);
            }
        } else {
            if (_isETH(token)) {
                require(msg.value >= transfer.amount, "INSUFFICENT_ETH_AMOUNT");
                // we only need transfer.amount, so we return the excess
                uint256 excess = msg.value.sub(transfer.amount);
                if (excess != 0) {
                    (bool success, ) = msg.sender.call{value: excess}("");
                    require(success, "TRANSFER_FAILED");
                }

                weth.deposit{value: transfer.amount}();
                weth.transfer(market, transfer.amount);
            } else {
                // its a transfer in of token. If its an XYT
                // we will auto approve the router to spend from the user account;
                if (data.isXyt(token)) {
                    _checkApproveRouter(token);
                }
                IERC20(token).safeTransferFrom(msg.sender, market, transfer.amount);
            }
        }
    }

    // Check if an user has approved the router to spend the amount
    // if not, approve the router to spend the token from the user account
    function _checkApproveRouter(address token) internal {
        uint256 allowance = IPendleBaseToken(token).allowance(msg.sender, address(this));
        if (allowance >= REASONABLE_ALLOWANCE_AMOUNT) return;
        IPendleYieldToken(token).approveRouter(msg.sender);
    }

    // There shouldn't be any fund in here
    // hence governance is allowed to withdraw anything from here.
    function _allowedToWithdraw(address) internal pure override returns (bool allowed) {
        allowed = true;
    }
}