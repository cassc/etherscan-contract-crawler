// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./interfaces/IERC20Token.sol";
import "./interfaces/IInsurancePool.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IUnitas.sol";
import "./utils/AddressUtils.sol";
import "./utils/Errors.sol";
import "./utils/ScalingUtils.sol";
import "./SwapFunctions.sol";
import "./PoolBalances.sol";

/**
 * @title Unitas
 * @notice This contract is primarily used for exchanging tokens and managing reserve assets
 */
contract Unitas is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IUnitas,
    PoolBalances,
    SwapFunctions
{
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant PORTFOLIO_ROLE = keccak256("PORTFOLIO_ROLE");

    IOracle public oracle;
    address public surplusPool;
    address public insurancePool;
    ITokenManager public tokenManager;

    /**
     * @notice Emitted when `oracle` is updated
     */
    event SetOracle(address indexed newOracle);
    /**
     * @notice Emitted when `surplusPool` is updated
     */
    event SetSurplusPool(address indexed newSurplusPool);
    /**
     * @notice Emitted when `insurancePool` is updated
     */
    event SetInsurancePool(address indexed newInsurancePool);
    /**
     * @notice Emitted when `tokenManager` is updated
     */
    event SetTokenManager(ITokenManager indexed newTokenManager);
    /**
     * @notice Emitted when `sender` swap tokens
     */
    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        address feeToken,
        uint256 fee,
        uint24 feeNumerator,
        uint256 price
    );
    /**
     * @notice Emitted when swapping `fee` is sent to `receiver`
     */
    event SwapFeeSent(address indexed feeToken, address indexed receiver, uint256 fee);

    // ============================== ERRORS ==============================

    error NotTimelock(address caller);
    error NotGuardian(address caller);
    error NotPortfolio(address caller);

    // ============================== MODIFIERS ==============================

    /**
     * @notice Reverts if `msg.sender` does not have `TIMELOCK_ROLE`
     */
    modifier onlyTimelock() {
        if (!hasRole(TIMELOCK_ROLE, msg.sender))
            revert NotTimelock(msg.sender);
        _;
    }

    /**
     * @notice Reverts if `msg.sender` does not have `GUARDIAN_ROLE`
     */
    modifier onlyGuardian() {
        if (!hasRole(GUARDIAN_ROLE, msg.sender))
            revert NotGuardian(msg.sender);
        _;
    }

    /**
     * @notice Reverts if `account` does not have `PORTFOLIO_ROLE`
     */
    modifier onlyPortfolio(address account) {
        if (!hasRole(PORTFOLIO_ROLE, account)) {
            revert NotPortfolio(account);
        }
        _;
    }


    // ============================== CONSTRUCTOR ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     * @param config_ `InitializeConfig` to init states
     */
    function initialize(InitializeConfig calldata config_) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(TIMELOCK_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(PORTFOLIO_ROLE, GUARDIAN_ROLE);

        _grantRole(GOVERNOR_ROLE, config_.governor);
        _grantRole(GUARDIAN_ROLE, config_.guardian);
        _grantRole(TIMELOCK_ROLE, config_.timelock);
        _grantRole(PORTFOLIO_ROLE, config_.guardian);

        _setOracle(config_.oracle);
        _setSurplusPool(config_.surplusPool);
        _setInsurancePool(config_.insurancePool);
        _setTokenManager(config_.tokenManager);
    }

    // ============================== Timelock FUNCTIONS ===========================

    /**
     * @notice Updates the address of `oracle` by `newOracle`
     */
    function setOracle(address newOracle) external onlyTimelock {
        _setOracle(newOracle);
    }

    /**
     * @notice Updates the address of `surplusPool` by `newSurplusPool`
     */
    function setSurplusPool(address newSurplusPool) external onlyTimelock {
        _setSurplusPool(newSurplusPool);
    }

    /**
     * @notice Updates the address of `insurancePool` by `newInsurancePool`
     */
    function setInsurancePool(address newInsurancePool) external onlyTimelock {
        _setInsurancePool(newInsurancePool);
    }

    /**
     * @notice Updates the address of `tokenManager`
     */
    function setTokenManager(ITokenManager newTokenManager) external onlyTimelock {
        _setTokenManager(newTokenManager);
    }

    // ============================== GUARDIAN FUNCTIONS ===========================

    /**
     * @notice Pause token swapping
     */
    function pause() public onlyGuardian {
        _pause();
    }

    /**
     * @notice Resume token swapping
     */
    function unpause() public onlyGuardian {
        _unpause();
    }

    // ============================== EXTERNAL FUNCTIONS ===========================

    /**
     * @notice Swaps tokens
     * @param tokenIn The address of the token to be spent
     * @param tokenOut The address of the token to be obtained
     * @param amountType The type of the amount
     * @param amount When `amountType` is `In`, it's the number of `tokenIn` that the user wants to spend.
     *               When `amountType` is `Out`, it's the number of `tokenOut` that the user wants to obtain.
     * @return amountIn The amount of `tokenIn` spent
     * @return amountOut The amount of `tokenOut` obtained
     */
    function swap(address tokenIn, address tokenOut, AmountType amountType, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 amountIn, uint256 amountOut)
    {
        IERC20Token feeToken;
        uint256 fee;
        uint24 feeNumerator;
        uint256 price;
        ITokenManager.PairConfig memory pair = tokenManager.getPair(tokenIn, tokenOut);

        (amountIn, amountOut, feeToken, fee, feeNumerator, price) = _getSwapResult(pair, tokenIn, tokenOut, amountType, amount);

        _require(IERC20(tokenIn).balanceOf(msg.sender) >= amountIn, Errors.BALANCE_INSUFFICIENT);

        _swapIn(tokenIn, msg.sender, amountIn);

        _swapOut(tokenOut, msg.sender, amountOut);

        if (fee > 0) {
            address feeReceiver = surplusPool;
            feeToken.mint(feeReceiver, fee);
            emit SwapFeeSent(address(feeToken), feeReceiver, fee);
        }

        _checkReserveRatio(tokenOut == pair.baseToken ? pair.buyReserveRatioThreshold : pair.sellReserveRatioThreshold);

        emit Swapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut, address(feeToken), fee, feeNumerator, price);
    }

    /**
     * @notice Receives the portfolio from caller
     * @param token Address of the token
     * @param amount Amount of the portfolio
     */
    function receivePortfolio(address token, uint256 amount)
        external
        onlyPortfolio(msg.sender)
        nonReentrant
    {
        _receivePortfolio(token, msg.sender, amount);
    }

    /**
     * @notice Sends the portfolio to the receiver
     * @param token Address of the token
     * @param receiver Account to receive the portfolio
     * @param amount Amount of the portfolio
     */
    function sendPortfolio(address token, address receiver, uint256 amount)
        external
        onlyTimelock
        onlyPortfolio(receiver)
        nonReentrant
    {
        _sendPortfolio(token, receiver, amount);
    }

    /**
     * @notice Estimates swapping result for quoting
     * @param tokenIn The address of the token to be spent
     * @param tokenOut The address of the token to be obtained
     * @param amountType The type of the amount
     * @param amount When `amountType` is `In`, it's the number of `tokenIn` that the user wants to spend.
     *               When `amountType` is `Out`, it's the number of `tokenOut` that the user wants to obtain.
     * @return amountIn The amount of `tokenIn` to be spent
     * @return amountOut The amount of `tokenOut` to be obtained
     * @return feeToken The fee token
     * @return fee Swapping fee calculated in `feeToken`
     * @return feeNumerator The numerator of the fee fraction
     * @return price The price of `tokenIn`/`tokenOut`
     */
    function estimateSwapResult(address tokenIn, address tokenOut, AmountType amountType, uint256 amount)
        external
        view
        returns (uint256 amountIn, uint256 amountOut, IERC20Token feeToken, uint256 fee, uint24 feeNumerator, uint256 price)
    {
        ITokenManager.PairConfig memory pair = tokenManager.getPair(tokenIn, tokenOut);

        (amountIn, amountOut, feeToken, fee, feeNumerator, price) = _getSwapResult(pair, tokenIn, tokenOut, amountType, amount);
    }

    // ============================== PUBLIC FUNCTIONS ==============================

    /**
     * @notice Gets the reserve of `token`
     */
    function getReserve(address token) public view returns (uint256) {
        return _getBalance(token);
    }

    /**
     * @notice Gets the portfolio of `token`
     */
    function getPortfolio(address token) public view returns (uint256) {
        return _getPortfolio(token);
    }

    /**
     * @notice Gets the reserve status
     * @return reserveStatus `Undefined` when `reserves`, `collaterals` and `liabilities` are zero.
                              `Infinite` when `liabilities` is zero.
                              Otherwise `Finite`.
     * @return reserves Total reserves denominated in USD1
     * @return collaterals Total collaterals denominated in USD1
     * @return liabilities Total liabilities denominated in USD1
     * @return reserveRatio The numerator of the reserve ratio is expressed in 18 decimal places
     */
    function getReserveStatus()
        public
        view
        returns (ReserveStatus reserveStatus, uint256 reserves, uint256 collaterals, uint256 liabilities, uint256 reserveRatio)
    {
        (reserves, collaterals) = _getTotalReservesAndCollaterals();
        liabilities = _getTotalLiabilities();

        (reserveStatus, reserveRatio) = _getReserveStatus(reserves + collaterals, liabilities);
    }

    // ============================== INTERNAL FUNCTIONS ==============================

    function _setOracle(address newOracle) internal {
        AddressUtils.checkContract(newOracle);
        oracle = IOracle(newOracle);
        emit SetOracle(newOracle);
    }

    function _setSurplusPool(address newSurplusPool) internal {
        _require(newSurplusPool != address(0), Errors.ADDRESS_ZERO);
        surplusPool = newSurplusPool;
        emit SetSurplusPool(newSurplusPool);
    }

    function _setInsurancePool(address newInsurancePool) internal {
        AddressUtils.checkContract(newInsurancePool);
        insurancePool = newInsurancePool;
        emit SetInsurancePool(newInsurancePool);
    }

    function _setTokenManager(ITokenManager newTokenManager) internal {
        AddressUtils.checkContract(address(newTokenManager));
        tokenManager = newTokenManager;
        emit SetTokenManager(newTokenManager);
    }

    /**
     * @notice Spends tokens for swapping
     * @param token The address of the token
     * @param spender The account to spend tokens
     * @param amount The amount to be consumed
     */
    function _swapIn(address token, address spender, uint256 amount) internal {
        ITokenManager.TokenType tokenType = tokenManager.getTokenType(token);

        require(tokenType != ITokenManager.TokenType.Undefined);

        if (tokenType == ITokenManager.TokenType.Asset) {
            _setBalance(token, _getBalance(token) + amount);
            IERC20(token).safeTransferFrom(spender, address(this), amount);
        } else {
            IERC20Token(token).burn(spender, amount);
        }
    }

    /**
     * @notice Receives tokens for swapping
     * @param token The address of the token
     * @param receiver The account to receive tokens
     * @param amount The amount to be obtained
     */
    function _swapOut(address token, address receiver, uint256 amount) internal {
        ITokenManager.TokenType tokenType = tokenManager.getTokenType(token);

        require(tokenType != ITokenManager.TokenType.Undefined);

        if (tokenType == ITokenManager.TokenType.Asset) {
            uint256 tokenReserve = _getBalance(token);
            uint256 reserveAmount = amount.min(tokenReserve - _getPortfolio(token));

            if (amount > reserveAmount) {
                uint256 collateralAmount = amount - reserveAmount;

                // Pull the collateral from insurance pool
                IInsurancePool(insurancePool).withdrawCollateral(token, collateralAmount);
            }

            _setBalance(token, tokenReserve - reserveAmount);
            IERC20(token).safeTransfer(receiver, amount);
        } else {
            IERC20Token(token).mint(receiver, amount);
        }
    }

    /**
     * @notice Gets the swapping result
     * @param pair The setting of the pair
     * @param tokenIn The address of the token to be spent
     * @param tokenOut The address of the token to be obtained
     * @param amountType The type of the amount
     * @param amount When `amountType` is `In`, it's the number of `tokenIn` that the user wants to spend.
     *               When `amountType` is `Out`, it's the number of `tokenOut` that the user wants to obtain.
     * @return amountIn The amount of `tokenIn` to be spent
     * @return amountOut The amount of `tokenOut` to be obtained
     * @return feeToken The fee token is always USD1
     * @return fee Swapping fee calculated in USD1
     * @return feeNumerator The numerator of the fee fraction
     * @return price The price of `tokenIn`/`tokenOut`
     */
    function _getSwapResult(
        ITokenManager.PairConfig memory pair,
        address tokenIn,
        address tokenOut,
        AmountType amountType,
        uint256 amount
    )
        internal
        view
        returns (uint256 amountIn, uint256 amountOut, IERC20Token feeToken, uint256 fee, uint24 feeNumerator, uint256 price)
    {
        _checkAmountPositive(amount);

        // Checks the tokens of the pair config are valid
        bool isBuy = tokenOut == pair.baseToken;
        _require(
            (isBuy && tokenIn == pair.quoteToken) ||
                (tokenOut == pair.quoteToken && tokenIn == pair.baseToken),
            Errors.PAIR_INVALID
        );

        address priceQuoteToken = _getPriceQuoteToken(tokenIn, tokenOut);
        price = oracle.getLatestPrice(priceQuoteToken);
        _checkPrice(priceQuoteToken, price);

        feeNumerator = isBuy ? pair.buyFee : pair.sellFee;
        feeToken = IERC20Token(priceQuoteToken == tokenIn ? tokenOut : tokenIn);

        SwapRequest memory request;
        request.tokenIn = tokenIn;
        request.tokenOut = tokenOut;
        request.amountType = amountType;
        request.amount = amount;
        request.feeNumerator = feeNumerator;
        request.feeBase = tokenManager.SWAP_FEE_BASE();
        request.feeToken = address(feeToken);
        request.price = price;
        request.priceBase = 10 ** oracle.decimals();
        request.quoteToken = priceQuoteToken;

        (amountIn, amountOut, fee) = _calculateSwapResult(request);

        _require(amountIn > 0 && amountOut > 0, Errors.SWAP_RESULT_INVALID);

        if (tokenIn == priceQuoteToken) {
            // The base currency of oracle price is USD1, inverts the price when buying USD1
            price = request.priceBase * request.priceBase / price;
        }
    }

    /**
     * @notice Gets the reserve status and reserve ratio.
     * @param allReserves Sum of the reserves and the collaterals denominated in USD1
     * @param liabilities Total liabilities denominated in USD1
     * @return reserveStatus `Undefined` when `allReserves` and `liabilities` are zero.
                              `Infinite` when `liabilities` is zero.
                              Otherwise `Finite`.
     * @return reserveRatio The numerator of the reserve ratio is expressed in 18 decimal places
     */
    function _getReserveStatus(uint256 allReserves, uint256 liabilities)
        internal
        view
        returns (ReserveStatus reserveStatus, uint256 reserveRatio)
    {
        if (liabilities == 0) {
            reserveStatus = allReserves == 0 ? ReserveStatus.Undefined : ReserveStatus.Infinite;
        } else {
            reserveStatus = ReserveStatus.Finite;

            // All decimals of parameters are the same as USD1
            uint256 valueBase = 10 ** tokenManager.usd1().decimals();

            reserveRatio = ScalingUtils.scaleByBases(
                allReserves * valueBase / liabilities,
                valueBase,
                tokenManager.RESERVE_RATIO_BASE()
            );
        }
    }

    /**
     * @notice Gets total reserves and total collaterals in USD1
     */
    function _getTotalReservesAndCollaterals() internal view returns (uint256 reserves, uint256 collaterals) {
        address baseToken = address(tokenManager.usd1());
        uint8 tokenTypeValue = uint8(ITokenManager.TokenType.Asset);
        uint256 tokenCount = tokenManager.tokenLength(tokenTypeValue);
        uint256 priceBase = 10 ** oracle.decimals();

        for (uint256 i; i < tokenCount; i++) {
            address token = tokenManager.tokenByIndex(tokenTypeValue, i);
            uint256 tokenReserve = _getBalance(token);
            uint256 tokenCollateral = IInsurancePool(insurancePool).getCollateral(token);

            if (tokenReserve > 0 || tokenCollateral > 0) {
                uint256 price = oracle.getLatestPrice(token);

                reserves += _convert(
                    token,
                    baseToken,
                    tokenReserve,
                    MathUpgradeable.Rounding.Down,
                    price,
                    priceBase,
                    token
                );

                collaterals += _convert(
                    token,
                    baseToken,
                    tokenCollateral,
                    MathUpgradeable.Rounding.Down,
                    price,
                    priceBase,
                    token
                );
            }
        }
    }

    /**
     * @notice Gets total liabilities in USD1
     */
    function _getTotalLiabilities() internal view returns (uint256 liabilities) {
        address baseToken = address(tokenManager.usd1());
        uint8 tokenTypeValue = uint8(ITokenManager.TokenType.Stable);
        uint256 tokenCount = tokenManager.tokenLength(tokenTypeValue);
        uint256 priceBase = 10 ** oracle.decimals();

        for (uint256 i; i < tokenCount; i++) {
            address token = tokenManager.tokenByIndex(tokenTypeValue, i);
            uint256 tokenSupply = IERC20Token(token).totalSupply();

            if (token == baseToken) {
                // Adds up directly when the token is USD1
                liabilities += tokenSupply;
            } else if (tokenSupply > 0) {
                uint256 price = oracle.getLatestPrice(token);

                liabilities += _convert(
                    token,
                    baseToken,
                    tokenSupply,
                    MathUpgradeable.Rounding.Down,
                    price,
                    priceBase,
                    token
                );
            }
        }
    }

    /**
     * @notice Gets the quote token of oracle price by two token addresses.
     *          Because of the base currencies of all oracle prices are always USD1 (e.g., USD1/USDT and USD1/USD91),
     *          one of `tokenX` or `tokenY` must be USD1, and the other must not be USD1.
     * @dev The caller must ensure that both tokens are in the pool
     * @param tokenX Address of base currency or quote currency
     * @param tokenY Address of base currency or quote currency
     * @return quoteToken The quote currency of oracle price
     */
    function _getPriceQuoteToken(address tokenX, address tokenY) internal view returns (address quoteToken) {
        _require(tokenX != tokenY, Errors.PAIR_INVALID);

        address baseToken = address(tokenManager.usd1());
        _require(baseToken != address(0), Errors.USD1_NOT_SET);

        bool isXBase = tokenX == baseToken;
        _require(isXBase || tokenY == baseToken, Errors.PAIR_INVALID);

        quoteToken = isXBase ? tokenY : tokenX;
    }

    /**
     * @notice Reverts if the price or the tolerance range is invalid
     * @param quoteToken Address of quote token to get the tolerance range
     * @param price The price of USD1/`quoteToken`
     */
    function _checkPrice(address quoteToken, uint256 price) internal view {
        (uint256 minPrice, uint256 maxPrice) = tokenManager.getPriceTolerance(quoteToken);

        _require(minPrice > 0 && maxPrice > 0, Errors.PRICE_TOLERANCE_INVALID);
        _require(minPrice <= price && price <= maxPrice, Errors.PRICE_INVALID);
    }

    /**
     * @notice Checks the reserve ratio is sufficient when `reserveRatioThreshold` is greater than zero
     */
    function _checkReserveRatio(uint232 reserveRatioThreshold) internal view {
        if (reserveRatioThreshold == 0) {
            return;
        } else {
            (uint256 reserves, uint256 collaterals) = _getTotalReservesAndCollaterals();
            uint256 allReserves = reserves + collaterals;
            uint256 liabilities = _getTotalLiabilities();

            (ReserveStatus reserveStatus, uint256 reserveRatio) = _getReserveStatus(allReserves, liabilities);

            if (reserveStatus != ReserveStatus.Infinite) {
                _require(reserveRatio > reserveRatioThreshold, Errors.RESERVE_RATIO_NOT_GREATER_THAN_THRESHOLD);
            }
        }
    }
}