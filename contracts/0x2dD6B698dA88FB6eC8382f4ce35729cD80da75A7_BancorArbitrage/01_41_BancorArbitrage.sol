// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import { IBalancerVault } from "../exchanges/interfaces/IBalancerVault.sol";
import { IFlashLoanRecipient as BalancerFlashloanRecipient } from "../exchanges/interfaces/IBalancerVault.sol";

import { Token } from "../token/Token.sol";
import { TokenLibrary } from "../token/TokenLibrary.sol";
import { IVersioned } from "../utility/interfaces/IVersioned.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { Utils, ZeroValue } from "../utility/Utils.sol";
import { IBancorNetwork, IFlashLoanRecipient } from "../exchanges/interfaces/IBancorNetwork.sol";
import { IBancorNetworkV2 } from "../exchanges/interfaces/IBancorNetworkV2.sol";
import { ICarbonController, TradeAction } from "../exchanges/interfaces/ICarbonController.sol";
import { PPM_RESOLUTION } from "../utility/Constants.sol";
import { MathEx } from "../utility/MathEx.sol";

/**
 * @dev BancorArbitrage contract
 */
contract BancorArbitrage is ReentrancyGuardUpgradeable, Utils, Upgradeable {
    using SafeERC20 for IERC20;
    using TokenLibrary for Token;
    using Address for address payable;

    error InvalidTradePlatformId();
    error InvalidFlashloanPlatformId();
    error InvalidRouteLength();
    error InvalidInitialAndFinalTokens();
    error InvalidFlashloanFormat();
    error InvalidFlashLoanCaller();
    error MinTargetAmountTooHigh();
    error InvalidSourceToken();
    error InvalidETHAmountSent();
    error InsufficientBurn();

    // trade args
    struct Route {
        uint16 platformId;
        Token targetToken;
        uint256 minTargetAmount;
        uint256 deadline;
        address customAddress;
        uint256 customInt;
        bytes customData;
    }

    // trade args v2
    struct TradeRoute {
        uint16 platformId;
        Token sourceToken;
        Token targetToken;
        uint256 sourceAmount;
        uint256 minTargetAmount;
        uint256 deadline;
        address customAddress;
        uint256 customInt;
        bytes customData;
    }

    // flashloan args
    struct Flashloan {
        uint16 platformId;
        IERC20[] sourceTokens;
        uint256[] sourceAmounts;
    }

    // rewards settings
    struct Rewards {
        uint32 percentagePPM;
        uint256 maxAmount;
    }

    // platforms
    struct Platforms {
        IBancorNetworkV2 bancorNetworkV2;
        IBancorNetwork bancorNetworkV3;
        IUniswapV2Router02 uniV2Router;
        ISwapRouter uniV3Router;
        IUniswapV2Router02 sushiswapRouter;
        ICarbonController carbonController;
        IBalancerVault balancerVault;
    }

    // platform ids
    uint16 public constant PLATFORM_ID_BANCOR_V2 = 1;
    uint16 public constant PLATFORM_ID_BANCOR_V3 = 2;
    uint16 public constant PLATFORM_ID_UNISWAP_V2 = 3;
    uint16 public constant PLATFORM_ID_UNISWAP_V3 = 4;
    uint16 public constant PLATFORM_ID_SUSHISWAP = 5;
    uint16 public constant PLATFORM_ID_CARBON = 6;
    uint16 public constant PLATFORM_ID_BALANCER = 7;

    // minimum number of trade routes supported
    uint256 private constant MIN_ROUTE_LENGTH = 2;
    // maximum number of trade routes supported
    uint256 private constant MAX_ROUTE_LENGTH = 10;

    // the bnt contract
    IERC20 internal immutable _bnt;

    // WETH9 contract
    IERC20 internal immutable _weth;

    // bancor v2 network contract
    IBancorNetworkV2 internal immutable _bancorNetworkV2;

    // bancor v3 network contract
    IBancorNetwork internal immutable _bancorNetworkV3;

    // uniswap v2 router contract
    IUniswapV2Router02 internal immutable _uniswapV2Router;

    // uniswap v3 router contract
    ISwapRouter internal immutable _uniswapV3Router;

    // sushiSwap router contract
    IUniswapV2Router02 internal immutable _sushiSwapRouter;

    // Carbon controller contract
    ICarbonController internal immutable _carbonController;

    // Balancer Vault
    IBalancerVault internal immutable _balancerVault;

    // Protocol wallet address
    address internal immutable _protocolWallet;

    // rewards defaults
    Rewards internal _rewards;

    // deprecated variable
    uint256 private deprecated;

    // upgrade forward-compatibility storage gap
    uint256[MAX_GAP - 3] private __gap;

    /**
     * @dev triggered after a successful arb is executed
     */
    event ArbitrageExecuted(
        address indexed caller,
        uint16[] platformIds,
        address[] tokenPath,
        address[] sourceTokens,
        uint256[] sourceAmounts,
        uint256[] protocolAmounts,
        uint256[] rewardAmounts
    );

    /**
     * @dev triggered when the rewards settings are updated
     */
    event RewardsUpdated(
        uint32 prevPercentagePPM,
        uint32 newPercentagePPM,
        uint256 prevMaxAmount,
        uint256 newMaxAmount
    );

    /**
     * @dev a "virtual" constructor that is only used to set immutable state variables
     */
    constructor(
        IERC20 initBnt,
        address initProtocolWallet,
        Platforms memory platforms
    )
        validAddress(address(initBnt))
        validAddress(address(initProtocolWallet))
        validAddress(address(platforms.bancorNetworkV2))
        validAddress(address(platforms.bancorNetworkV3))
        validAddress(address(platforms.uniV2Router))
        validAddress(address(platforms.uniV3Router))
        validAddress(address(platforms.sushiswapRouter))
        validAddress(address(platforms.carbonController))
        validAddress(address(platforms.balancerVault))
    {
        _bnt = initBnt;
        _weth = IERC20(platforms.uniV2Router.WETH());
        _protocolWallet = initProtocolWallet;
        _bancorNetworkV2 = platforms.bancorNetworkV2;
        _bancorNetworkV3 = platforms.bancorNetworkV3;
        _uniswapV2Router = platforms.uniV2Router;
        _uniswapV3Router = platforms.uniV3Router;
        _sushiSwapRouter = platforms.sushiswapRouter;
        _carbonController = platforms.carbonController;
        _balancerVault = platforms.balancerVault;
    }

    /**
     * @dev fully initializes the contract and its parents
     */
    function initialize() external initializer {
        __BancorArbitrage_init();
    }

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract and its parents
     */
    function __BancorArbitrage_init() internal onlyInitializing {
        __ReentrancyGuard_init();
        __Upgradeable_init();

        __BancorArbitrage_init_unchained();
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __BancorArbitrage_init_unchained() internal onlyInitializing {
        _rewards = Rewards({ percentagePPM: 100000, maxAmount: 100 * 1e18 });
    }

    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}

    /**
     * @inheritdoc Upgradeable
     */
    function version() public pure override(Upgradeable) returns (uint16) {
        return 4;
    }

    /**
     * @dev checks whether the specified number of routes is supported
     */
    modifier validRouteLength(uint256 length) {
        // validate inputs
        _validRouteLength(length);

        _;
    }

    /**
     * @dev validRouteLength logic for gas optimization
     */
    function _validRouteLength(uint256 length) internal pure {
        if (length < MIN_ROUTE_LENGTH || length > MAX_ROUTE_LENGTH) {
            revert InvalidRouteLength();
        }
    }

    /**
     * @dev sets the rewards settings
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setRewards(
        Rewards calldata newRewards
    ) external onlyAdmin validFee(newRewards.percentagePPM) greaterThanZero(newRewards.maxAmount) {
        uint32 prevPercentagePPM = _rewards.percentagePPM;
        uint256 prevMaxAmount = _rewards.maxAmount;

        // return if the rewards are the same
        if (prevPercentagePPM == newRewards.percentagePPM && prevMaxAmount == newRewards.maxAmount) {
            return;
        }

        _rewards = newRewards;

        emit RewardsUpdated({
            prevPercentagePPM: prevPercentagePPM,
            newPercentagePPM: newRewards.percentagePPM,
            prevMaxAmount: prevMaxAmount,
            newMaxAmount: newRewards.maxAmount
        });
    }

    /**
     * @dev returns the rewards settings
     */
    function rewards() external view returns (Rewards memory) {
        return _rewards;
    }

    /**
     * @dev returns the min bnt burn amount
     * note: deprecated
     */
    function minBurn() external pure returns (uint256) {
        return 0;
    }

    /**
     * @dev execute multi-step arbitrage trade between exchanges using a flashloan from Bancor Network V3
     * note: deprecated
     */
    function flashloanAndArb(Route[] calldata routes, Token token, uint256 sourceAmount) external {
        // convert route array to new format
        TradeRoute[] memory routesV2 = _convertRouteV1toV2(routes, token, sourceAmount);
        // create flashloan struct
        IERC20[] memory sourceTokens = new IERC20[](1);
        uint256[] memory sourceAmounts = new uint256[](1);
        sourceTokens[0] = IERC20(address(token));
        sourceAmounts[0] = sourceAmount;
        Flashloan[] memory flashloan = new Flashloan[](1);
        flashloan[0] = Flashloan({
            platformId: PLATFORM_ID_BANCOR_V3,
            sourceTokens: sourceTokens,
            sourceAmounts: sourceAmounts
        });
        // perform arb
        flashloanAndArbV2(flashloan, routesV2);
    }

    /**
     * @dev execute multi-step arbitrage trade between exchanges using one or more flashloans
     */
    function flashloanAndArbV2(
        Flashloan[] memory flashloans,
        TradeRoute[] memory routes
    ) public nonReentrant validRouteLength(routes.length) validateFlashloans(flashloans) {
        // abi encode the data to be passed in to the flashloan platform
        bytes memory encodedData = _encodeFlashloanData(flashloans, routes);
        // take flashloan
        _takeFlashloan(flashloans[0], encodedData);

        // allocate the rewards
        (address[] memory sourceTokens, uint256[] memory sourceAmounts) = _extractTokensAndAmounts(flashloans);
        _allocateRewards(sourceTokens, sourceAmounts, routes, msg.sender);
    }

    /**
     * @dev callback function for bancor V3 flashloan
     * @dev performs the arbitrage trades
     */
    function onFlashLoan(
        address caller,
        IERC20 erc20Token,
        uint256 amount,
        uint256 feeAmount,
        bytes memory data
    ) external {
        // validate inputs
        if (msg.sender != address(_bancorNetworkV3) || caller != address(this)) {
            revert InvalidFlashLoanCaller();
        }

        // execute the next flashloan or the arbitrage
        _decodeAndActOnFlashloanData(data);

        // return the flashloan
        Token(address(erc20Token)).safeTransfer(msg.sender, amount + feeAmount);
    }

    /**
     * @dev callback function for Balancer flashloan
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        if (msg.sender != address(_balancerVault)) {
            revert InvalidFlashLoanCaller();
        }

        // execute the next flashloan or the arbitrage
        _decodeAndActOnFlashloanData(userData);

        // return the flashloans
        for (uint256 i = 0; i < tokens.length; i = uncheckedInc(i)) {
            Token(address(tokens[i])).safeTransfer(msg.sender, amounts[i] + feeAmounts[i]);
        }
    }

    /**
     * @dev execute multi-step arbitrage trade between exchanges using user funds
     * @dev must approve token before executing the function
     */
    function fundAndArb(
        TradeRoute[] calldata routes,
        Token token,
        uint256 sourceAmount
    ) external payable nonReentrant validRouteLength(routes.length) greaterThanZero(sourceAmount) {
        // perform validations
        _validateFundAndArbParams(token, routes[routes.length - 1].targetToken, sourceAmount, msg.value);

        // transfer the tokens from user
        token.safeTransferFrom(msg.sender, address(this), sourceAmount);

        // perform the arbitrage
        _arbitrageV2(routes);

        // return the tokens to the user
        token.safeTransfer(msg.sender, sourceAmount);

        // allocate the rewards
        address[] memory sourceTokens = new address[](1);
        uint256[] memory sourceAmounts = new uint256[](1);
        sourceTokens[0] = address(token);
        sourceAmounts[0] = sourceAmount;
        _allocateRewards(sourceTokens, sourceAmounts, routes, msg.sender);
    }

    /**
     * @dev perform validations for fundAndArb functions
     */
    function _validateFundAndArbParams(
        Token token,
        Token finalToken,
        uint256 sourceAmount,
        uint256 value
    ) private view {
        // verify that the last token in the process is the arb token
        if (finalToken != token) {
            revert InvalidInitialAndFinalTokens();
        }
        // validate token is tradeable on v3
        if (!token.isEqual(_bnt) && _bancorNetworkV3.collectionByPool(token) == address(0)) {
            revert InvalidSourceToken();
        }
        // validate ETH amount sent with function is correct
        if (token.isNative()) {
            if (value != sourceAmount) {
                revert InvalidETHAmountSent();
            }
        } else {
            if (value > 0) {
                revert InvalidETHAmountSent();
            }
        }
    }

    /**
     * @dev encode the flashloan and route data
     */
    function _encodeFlashloanData(
        Flashloan[] memory flashloans,
        TradeRoute[] memory routes
    ) private pure returns (bytes memory encodedData) {
        Flashloan[] memory remainingFlashloans = new Flashloan[](flashloans.length - 1);
        for (uint256 i = 0; i < remainingFlashloans.length; i = uncheckedInc(i)) {
            remainingFlashloans[i] = flashloans[uncheckedInc(i)];
        }
        // abi encode the data to be passed in to the flashloan platform
        encodedData = abi.encode(remainingFlashloans, routes);
    }

    /**
     * @dev decode the flashloan data and either execute the next flashloan or the arbitrage
     */
    function _decodeAndActOnFlashloanData(bytes memory data) private {
        // decode the arb data
        (Flashloan[] memory flashloans, TradeRoute[] memory routes) = abi.decode(data, (Flashloan[], TradeRoute[]));
        // if the flashloan array is empty, perform the arbitrage
        if (flashloans.length == 0) {
            _arbitrageV2(routes);
        } else {
            // else execute the next flashloan in the sequence
            // abi encode the data to be passed in to the flashloan platform
            data = _encodeFlashloanData(flashloans, routes);
            // take flashloan
            _takeFlashloan(flashloans[0], data);
        }
    }

    /**
     * @dev flashloan logic
     */
    function _takeFlashloan(Flashloan memory flashloan, bytes memory data) private {
        if (flashloan.platformId == PLATFORM_ID_BANCOR_V3) {
            // take a flashloan on Bancor v3, execution continues in `onFlashloan`
            _bancorNetworkV3.flashLoan(
                Token(address(flashloan.sourceTokens[0])),
                flashloan.sourceAmounts[0],
                IFlashLoanRecipient(address(this)),
                data
            );
        } else if (flashloan.platformId == PLATFORM_ID_BALANCER) {
            // take a flashloan on Balancer, execution continues in `receiveFlashLoan`
            _balancerVault.flashLoan(
                BalancerFlashloanRecipient(address(this)),
                flashloan.sourceTokens,
                flashloan.sourceAmounts,
                data
            );
        } else {
            // invalid flashloan platform
            revert InvalidFlashloanPlatformId();
        }
    }

    /**
     * @dev arbitrage logic
     */
    function _arbitrageV2(TradeRoute[] memory routes) private {
        // perform the trade routes
        for (uint256 i = 0; i < routes.length; i = uncheckedInc(i)) {
            TradeRoute memory route = routes[i];
            uint256 sourceTokenBalance = route.sourceToken.balanceOf(address(this));
            uint256 sourceAmount;
            if (route.sourceAmount == 0 || route.sourceAmount > sourceTokenBalance) {
                sourceAmount = sourceTokenBalance;
            } else {
                sourceAmount = route.sourceAmount;
            }

            // perform the trade
            _trade(
                route.platformId,
                route.sourceToken,
                route.targetToken,
                sourceAmount,
                route.minTargetAmount,
                route.deadline,
                route.customAddress,
                route.customInt,
                route.customData
            );
        }
    }

    /**
     * @dev handles the trade logic per route
     */
    function _trade(
        uint256 platformId,
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount,
        uint256 minTargetAmount,
        uint256 deadline,
        address customAddress,
        uint256 customInt,
        bytes memory customData
    ) private {
        if (platformId == PLATFORM_ID_BANCOR_V2) {
            // allow the network to withdraw the source tokens
            _setPlatformAllowance(sourceToken, address(_bancorNetworkV2), sourceAmount);

            // build the conversion path
            address[] memory path = new address[](3);
            path[0] = address(sourceToken);
            path[1] = customAddress; // pool token address
            path[2] = address(targetToken);

            uint256 val = sourceToken.isNative() ? sourceAmount : 0;

            // perform the trade
            _bancorNetworkV2.convertByPath{ value: val }(
                path,
                sourceAmount,
                minTargetAmount,
                address(0x0),
                address(0x0),
                0
            );

            return;
        }

        if (platformId == PLATFORM_ID_BANCOR_V3) {
            // allow the network to withdraw the source tokens
            _setPlatformAllowance(sourceToken, address(_bancorNetworkV3), sourceAmount);

            uint256 val = sourceToken.isNative() ? sourceAmount : 0;

            // perform the trade
            _bancorNetworkV3.tradeBySourceAmountArb{ value: val }(
                sourceToken,
                targetToken,
                sourceAmount,
                minTargetAmount,
                deadline,
                address(0x0)
            );

            return;
        }

        if (platformId == PLATFORM_ID_UNISWAP_V2 || platformId == PLATFORM_ID_SUSHISWAP) {
            IUniswapV2Router02 router = platformId == PLATFORM_ID_UNISWAP_V2 ? _uniswapV2Router : _sushiSwapRouter;

            // allow the router to withdraw the source tokens
            _setPlatformAllowance(sourceToken, address(router), sourceAmount);

            // build the path
            address[] memory path = new address[](2);

            // perform the trade
            if (sourceToken.isNative()) {
                path[0] = address(_weth);
                path[1] = address(targetToken);
                router.swapExactETHForTokens{ value: sourceAmount }(minTargetAmount, path, address(this), deadline);
            } else if (targetToken.isNative()) {
                path[0] = address(sourceToken);
                path[1] = address(_weth);
                router.swapExactTokensForETH(sourceAmount, minTargetAmount, path, address(this), deadline);
            } else {
                path[0] = address(sourceToken);
                path[1] = address(targetToken);
                router.swapExactTokensForTokens(sourceAmount, minTargetAmount, path, address(this), deadline);
            }

            return;
        }

        if (platformId == PLATFORM_ID_UNISWAP_V3) {
            address tokenIn = sourceToken.isNative() ? address(_weth) : address(sourceToken);
            address tokenOut = targetToken.isNative() ? address(_weth) : address(targetToken);

            if (tokenIn == address(_weth)) {
                IWETH(address(_weth)).deposit{ value: sourceAmount }();
            }

            // allow the router to withdraw the source tokens
            _setPlatformAllowance(Token(tokenIn), address(_uniswapV3Router), sourceAmount);

            // build the params
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: uint24(customInt), // fee
                recipient: address(this),
                deadline: deadline,
                amountIn: sourceAmount,
                amountOutMinimum: minTargetAmount,
                sqrtPriceLimitX96: uint160(0)
            });

            // perform the trade
            _uniswapV3Router.exactInputSingle(params);

            if (tokenOut == address(_weth)) {
                IWETH(address(_weth)).withdraw(_weth.balanceOf(address(this)));
            }

            return;
        }

        if (platformId == PLATFORM_ID_CARBON) {
            // Carbon accepts 2^128 - 1 max for minTargetAmount
            if (minTargetAmount > type(uint128).max) {
                revert MinTargetAmountTooHigh();
            }
            // allow the carbon controller to withdraw the source tokens
            _setPlatformAllowance(sourceToken, address(_carbonController), sourceAmount);

            uint256 val = sourceToken.isNative() ? sourceAmount : 0;

            // decode the trade actions passed in as customData
            TradeAction[] memory tradeActions = abi.decode(customData, (TradeAction[]));

            // perform the trade
            _carbonController.tradeBySourceAmount{ value: val }(
                sourceToken,
                targetToken,
                tradeActions,
                deadline,
                uint128(minTargetAmount)
            );

            uint256 remainingSourceTokens = sourceToken.balanceOf(address(this));
            if (remainingSourceTokens > 0) {
                // transfer any remaining source tokens to the protocol wallet
                sourceToken.safeTransfer(_protocolWallet, remainingSourceTokens);
            }

            return;
        }

        revert InvalidTradePlatformId();
    }

    /**
     * @dev allocates the rewards to the caller and sends the rest to the protocol wallet
     */
    function _allocateRewards(
        address[] memory sourceTokens,
        uint256[] memory sourceAmounts,
        TradeRoute[] memory routes,
        address caller
    ) internal {
        uint256 tokenLength = sourceTokens.length;
        uint256[] memory protocolAmounts = new uint256[](tokenLength);
        uint256[] memory rewardAmounts = new uint256[](tokenLength);
        // transfer each of the remaining token balances to the caller and protocol wallet
        for (uint256 i = 0; i < tokenLength; i = uncheckedInc(i)) {
            Token sourceToken = Token(sourceTokens[i]);
            uint256 balance = sourceToken.balanceOf(address(this));
            uint256 rewardAmount = MathEx.mulDivF(balance, _rewards.percentagePPM, PPM_RESOLUTION);
            uint256 protocolAmount;
            // safe because _rewards.percentagePPM <= PPM_RESOLUTION
            unchecked {
                protocolAmount = balance - rewardAmount;
            }
            // handle protocol amount
            if (protocolAmount > 0) {
                if (sourceToken.isEqual(_bnt)) {
                    // if token is bnt burn it directly
                    // transferring bnt to the token's address triggers a burn
                    sourceToken.safeTransfer(address(_bnt), protocolAmount);
                } else {
                    // else transfer to protocol wallet
                    sourceToken.safeTransfer(_protocolWallet, protocolAmount);
                }
            }
            // handle reward amount
            if (rewardAmount > 0) {
                sourceToken.safeTransfer(caller, rewardAmount);
            }
            // set current reward and protocol amounts for the event
            rewardAmounts[i] = rewardAmount;
            protocolAmounts[i] = protocolAmount;
        }

        (uint16[] memory platformIds, address[] memory path) = _buildArbPath(routes);
        emit ArbitrageExecuted(caller, platformIds, path, sourceTokens, sourceAmounts, protocolAmounts, rewardAmounts);
    }

    /**
     * @dev build arb path from TradeRoute array
     */
    function _buildArbPath(
        TradeRoute[] memory routes
    ) private pure returns (uint16[] memory platformIds, address[] memory path) {
        platformIds = new uint16[](routes.length);
        path = new address[](routes.length * 2);
        for (uint256 i = 0; i < routes.length; i = uncheckedInc(i)) {
            platformIds[i] = routes[i].platformId;
            path[i * 2] = address(routes[i].sourceToken);
            path[uncheckedInc(i * 2)] = address(routes[i].targetToken);
        }
    }

    /**
     * @dev extract tokens and amounts from Flashloan array
     */
    function _extractTokensAndAmounts(
        Flashloan[] memory flashloans
    ) private pure returns (address[] memory, uint256[] memory) {
        uint256 totalLength = 0;
        for (uint256 i = 0; i < flashloans.length; i = uncheckedInc(i)) {
            totalLength += flashloans[i].sourceTokens.length;
        }

        address[] memory tokens = new address[](totalLength);
        uint256[] memory amounts = new uint256[](totalLength);

        uint256 index = 0;
        for (uint256 i = 0; i < flashloans.length; i = uncheckedInc(i)) {
            for (uint256 j = 0; j < flashloans[i].sourceTokens.length; j = uncheckedInc(j)) {
                tokens[index] = address(flashloans[i].sourceTokens[j]);
                amounts[index] = flashloans[i].sourceAmounts[j];
                index = uncheckedInc(index);
            }
        }

        return (tokens, amounts);
    }

    /**
     * @dev convert a V1 Route array to V2
     */
    function _convertRouteV1toV2(
        Route[] calldata routes,
        Token sourceToken,
        uint256 sourceAmount
    ) private pure returns (TradeRoute[] memory routesV2) {
        routesV2 = new TradeRoute[](routes.length);
        if (routes.length == 0) {
            return routesV2;
        }
        routesV2[0].sourceToken = sourceToken;
        routesV2[0].sourceAmount = sourceAmount;
        // set each route details
        for (uint256 i = 0; i < routes.length; i = uncheckedInc(i)) {
            Route memory route = routes[i];
            TradeRoute memory routeV2 = routesV2[i];
            // copy mutual parts
            routeV2.platformId = route.platformId;
            routeV2.targetToken = route.targetToken;
            routeV2.minTargetAmount = route.minTargetAmount;
            routeV2.deadline = route.deadline;
            routeV2.customAddress = route.customAddress;
            routeV2.customInt = route.customInt;
            routeV2.customData = route.customData;
            // set source token and amount
            if (i != 0) {
                routeV2.sourceToken = routes[i - 1].targetToken;
                routeV2.sourceAmount = 0;
            }
        }
    }

    /**
     * @dev set platform allowance to the max amount if it's less than the input amount
     */
    function _setPlatformAllowance(Token token, address platform, uint256 inputAmount) private {
        if (token.isNative()) {
            return;
        }
        uint256 allowance = token.toIERC20().allowance(address(this), platform);
        if (allowance < inputAmount) {
            // increase allowance to the max amount if allowance < inputAmount
            token.safeIncreaseAllowance(platform, type(uint256).max - allowance);
        }
    }

    function uncheckedInc(uint256 i) private pure returns (uint256 j) {
        unchecked {
            j = i + 1;
        }
    }

    /**
     * @dev perform various checks for flashloan source tokens and amounts
     *      check if any of the flashloan amounts are zero in value
     */
    modifier validateFlashloans(Flashloan[] memory flashloans) {
        if (flashloans.length == 0) {
            revert InvalidFlashloanFormat();
        }
        for (uint256 i = 0; i < flashloans.length; i = uncheckedInc(i)) {
            Flashloan memory flashloan = flashloans[i];
            if (flashloan.sourceTokens.length == 0) {
                revert InvalidFlashloanFormat();
            }
            if (flashloan.sourceTokens.length != flashloan.sourceAmounts.length) {
                revert InvalidFlashloanFormat();
            }
            if (flashloan.platformId == PLATFORM_ID_BANCOR_V3 && flashloan.sourceTokens.length > 1) {
                revert InvalidFlashloanFormat();
            }
            // check source amounts are not zero in value
            uint256[] memory sourceAmounts = flashloan.sourceAmounts;
            for (uint256 j = 0; j < sourceAmounts.length; j = uncheckedInc(j)) {
                if (sourceAmounts[j] == 0) {
                    revert ZeroValue();
                }
            }
        }
        _;
    }
}