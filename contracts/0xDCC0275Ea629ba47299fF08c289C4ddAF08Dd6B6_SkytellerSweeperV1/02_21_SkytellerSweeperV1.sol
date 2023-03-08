// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./SkytellerErrors.sol";
import "./interfaces/ISkytellerSweepDelegate.sol";
import "./interfaces/IWETH9.sol";

/**
 * @title SkytellerSweeperV1
 * @notice Version 1 of the sweeper delegate for Skyteller
 */
contract SkytellerSweeperV1 is ISkytellerSweepDelegate, Ownable2Step, Pausable, Initializable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev A token has been swept
    event Sweep(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed destination,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    );
    /// @dev Owner has set the intermediate token
    event SetIntermediateToken(address indexed token);
    /// @dev Owner has set the skyteller swap fee treasury
    event SetSkytellerSwapFeeTreasury(address indexed skytellerSwapFeeTreasury);

    /// @dev Owner has set the skyteller swap fee
    event SetSkytellerSwapFee(uint24 skytellerSwapFee);

    /// @dev Owner has set the minimum percent out
    event SetMinimumPercentOutBips(uint16 minimumPercentOutBips);

    /// @dev Owner has set the Uniswap router
    event SetUniswapRouter(address indexed uniswapRouter);

    /// @dev Owner has set the pool config
    event SetPool(address indexed token0, address indexed token1, uint24 fee);

    /// @dev Owner has rescued a ERC-1155 token
    event RescueERC1155(address indexed token, uint256 tokenId, uint256 amount);

    /// @dev Owner has rescued a ERC-721 token
    event RescueERC721(address indexed token, uint256 tokenId);

    /// @dev Owner has rescued a ERC-20 token

    event RescueERC20(address indexed token, uint256 amount);

    /// @dev Owner has rescued ETH
    event Rescue(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The configuration for a token's price feeds. If the token is pegged to USD, then
     *         no USD price feeds are consulted.
     * @param usdPegged Whether the token is pegged to USD
     * @param usd The address of the USD price feed
     * @param eth The address of the ETH price feed
     */
    struct TokenPriceFeedConfig {
        bool usdPegged;
        address usd;
        address eth;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint16 internal constant MINIMUM_SWAP_PERCENT_OUT_BIPS = 9850;
    uint16 internal constant BIPS_PRECISION = 10000;

    uint8 internal constant PRICE_DERIVATION_DECIMALS = 18;
    uint256 internal constant PRICE_DERIVATION_PRECISION = 10 ** PRICE_DERIVATION_DECIMALS;

    uint24 internal constant DEFAULT_SKYTELLER_SWAP_FEE = 7500;
    uint24 internal constant FEE_PRECISION = 1000000;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Uniswap V3 router
    ISwapRouter public uniswapRouter;

    /// @notice The WETH9 contract
    address public intermediateToken;

    /// @notice The treasury address for skyteller swap fees
    address public skytellerSwapFeeTreasury;

    /// @notice Fee for conducting swaps (1 bip = 10000)
    uint24 public skytellerSwapFee = DEFAULT_SKYTELLER_SWAP_FEE;

    /// @notice Minimum amount out for conducting swaps (1 bip = 100)
    uint16 public minimumPercentOutBips = MINIMUM_SWAP_PERCENT_OUT_BIPS;

    /// @dev The set of tokens that can be swept
    EnumerableSet.AddressSet internal _tokens;

    /// @notice Get the token price feed config
    mapping(address => TokenPriceFeedConfig) public tokenPriceFeedConfig;

    /// @notice Get the pool fee for a given token pair
    mapping(address => mapping(address => uint24)) internal poolFees;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTION
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _intermediateToken,
        address _owner,
        address _uniswapRouter,
        address _skytellerSwapFeeTreasury
    ) external initializer {
        _transferOwnership(_owner);
        intermediateToken = _intermediateToken;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        skytellerSwapFeeTreasury = _skytellerSwapFeeTreasury;
    }

    /*//////////////////////////////////////////////////////////////
                                  GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the pool fee for a given token pair.
     * @param token0 The first token in the pair
     * @param token1 The second token in the pair
     * @return The pool fee, or zero if none found
     */
    function poolFee(address token0, address token1) public view returns (uint24) {
        if (token0 > token1) {
            return poolFees[token0][token1];
        } else {
            return poolFees[token1][token0];
        }
    }

    /**
     * @notice Gets the number of tokens in our list of tokens that may possibly be swept
     * @return The number of tokens
     */
    function numTokens() external view returns (uint256) {
        return _tokens.length();
    }

    /**
     * @notice Gets the token at a given index
     * @param index The index of the token
     * @return The token address
     */
    function token(uint256 index) external view returns (address) {
        return _tokens.at(index);
    }

    /**
     * @notice Gets the array of tokens that may possibly be swept
     * @return The array of tokens
     */
    function tokens() external view returns (address[] memory) {
        return _tokens.values();
    }

    /**
     * @notice Whether this token has a price feed in USD
     * @param _token The token to check
     * @return Whether this token has a price feed in USD
     */
    function hasTokenPriceUsd(address _token) public view returns (bool) {
        return
            tokenPriceFeedConfig[_token].usdPegged || tokenPriceFeedConfig[_token].usd != address(0);
    }

    /**
     * @notice Whether this token has a price feed in ETH
     * @param _token The token to check
     * @return Whether this token has a price feed in ETH
     */
    function hasTokenPriceEth(address _token) public view returns (bool) {
        return tokenPriceFeedConfig[_token].eth != address(0);
    }

    /*//////////////////////////////////////////////////////////////
                           PRICE FEED CHECKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the price of token in terms of USD
     * @dev Reverts if price is negative
     * @param _token The token to get the price of
     * @return price The price of token in terms of USD
     * @return decimals The number of decimals in the price
     */
    function tokenPriceUsd(address _token) public view returns (uint256 price, uint8 decimals) {
        TokenPriceFeedConfig memory config = tokenPriceFeedConfig[_token];
        if (config.usdPegged) {
            return (1, 0);
        }
        (, int256 answer,,,) = AggregatorV3Interface(config.usd).latestRoundData();
        if (answer < 0) {
            revert Skyteller_NegativePrice(_token, config.usd);
        }

        return (uint256(answer), AggregatorV3Interface(config.usd).decimals());
    }

    /**
     * @notice Gets the price of token in terms of ETH
     * @dev Reverts if price is negative
     * @param _token The token to get the price of
     * @return price The price of token in terms of ETH
     * @return decimals The number of decimals in the price
     */
    function tokenPriceEth(address _token) public view returns (uint256 price, uint8 decimals) {
        TokenPriceFeedConfig memory config = tokenPriceFeedConfig[_token];
        (, int256 answer,,,) = AggregatorV3Interface(config.eth).latestRoundData();
        if (answer < 0) {
            revert Skyteller_NegativePrice(_token, config.eth);
        }
        return (uint256(answer), AggregatorV3Interface(config.eth).decimals());
    }

    /*//////////////////////////////////////////////////////////////
                           PRICE DERIVATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Derives the price of tokenIn in terms of tokenOut
     * @dev
     * @param tokenIn The token to derive the price of
     * @param tokenOut The token to derive the price in terms of
     * @return price The price of tokenIn in terms of tokenOut
     * @return decimals The number of decimals in the price
     */
    function derivePrice(address tokenIn, address tokenOut)
        public
        view
        returns (uint256 price, uint8 decimals)
    {
        if (tokenIn == tokenOut) {
            return (1, 0);
        }
        uint256 priceIn;
        uint8 decimalsIn;
        uint256 priceOut;
        uint8 decimalsOut;
        if (hasTokenPriceUsd(tokenIn) && hasTokenPriceUsd(tokenOut)) {
            (priceIn, decimalsIn) = tokenPriceUsd(tokenIn);
            (priceOut, decimalsOut) = tokenPriceUsd(tokenOut);
        } else if (hasTokenPriceEth(tokenIn) && hasTokenPriceEth(tokenOut)) {
            (priceIn, decimalsIn) = tokenPriceEth(tokenIn);
            (priceOut, decimalsOut) = tokenPriceEth(tokenOut);
        } else {
            revert Skyteller_NoPriceDerivation(tokenIn, tokenOut);
        }
        if (decimalsIn > decimalsOut) {
            decimals = decimalsIn;
            priceOut *= 10 ** (decimalsIn - decimalsOut);
        } else if (decimalsOut > decimalsIn) {
            decimals = decimalsOut;
            priceIn *= 10 ** (decimalsOut - decimalsIn);
        } else {
            decimals = decimalsIn;
        }
        return (priceIn * PRICE_DERIVATION_PRECISION / priceOut, PRICE_DERIVATION_DECIMALS);
    }

    /**
     * @notice Calculate the minimum amount of tokenOut to receive
     *         based on current price feed data
     * @dev The minimum amount is calculated as follows:
     *      minimumAmountOut = derivedPrice * amountIn * minimumOutPercent.
     *      The calculation also includes the percentage of the expected amount out
     *
     * @param tokenIn The token to swap from
     * @param tokenOut The token to swap to
     * @param amountIn The amount of tokenIn to swap
     * @return The minimum amount of tokenOut to receive
     */
    function minimumAmountOut(address tokenIn, address tokenOut, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        (uint256 derivedPrice, uint8 derivedPriceDecimals) = derivePrice(tokenIn, tokenOut);
        uint256 amountInPrecision = 10 ** IERC20Metadata(tokenIn).decimals();
        uint256 amountOutPrecision = 10 ** IERC20Metadata(tokenOut).decimals();

        // - minimumPercentOutBips: percent (in basis points) of the expected amount out
        // - BIPS_PRECISION: the number of basis points in 100% (10000)
        // - derivedPrice: the price of tokenIn expressed in tokenOut.
        //   E.g. for ETH/DAI if 1 ETH = 1500 DAI, derivedPrice = 1500
        // - derivedPriceDecimals: the number of decimals of the derived price
        // - amountIn: the amount of tokenIn we're pricing
        // - amountInPrecision: the number of decimals of amountIn
        // - amountOutPrecision: the number of decimals we'll have on the amountOut
        //
        // The calculation is essentially minimumPercentOut x amountIn x derivedPrice
        // The other terms are decimal math
        return (minimumPercentOutBips * amountOutPrecision * derivedPrice * amountIn)
            / (BIPS_PRECISION * amountInPrecision * 10 ** derivedPriceDecimals);
    }

    /*//////////////////////////////////////////////////////////////
                                SWEEP (+SWAP)
    //////////////////////////////////////////////////////////////*/

    /// @notice Sweep amountIn of tokenIn to tokenOut
    /// @param tokenIn The token to swap from
    /// @param tokenOut The token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @param destination The address to send the swapped tokens to
    /// @return amountOut The amount of tokenOut received
    function sweep(IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn, address destination)
        external
        whenNotPaused
        returns (uint256 amountOut)
    {
        uint256 fee;
        uint256 swapOut;
        if (tokenIn == tokenOut) {
            amountOut = amountIn;
        } else {
            swapOut = _swap(address(tokenIn), address(tokenOut), amountIn);
            fee = skytellerSwapFee * swapOut / FEE_PRECISION;
            amountOut = swapOut - fee;
            tokenOut.safeTransfer(skytellerSwapFeeTreasury, fee);
        }
        tokenOut.safeTransfer(destination, amountOut);
        emit Sweep(address(tokenIn), address(tokenOut), destination, amountIn, amountOut, fee);
    }

    /// @dev Swap tokens using Uniswap
    /// @param tokenIn The token to swap from
    /// @param tokenOut The token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @return swapOut The amount of tokenOut received
    function _swap(address tokenIn, address tokenOut, uint256 amountIn)
        internal
        returns (uint256 swapOut)
    {
        uint256 amountOutMinimum = minimumAmountOut(tokenIn, address(tokenOut), amountIn);
        IERC20(tokenIn).safeApprove(address(uniswapRouter), amountIn);
        uint24 poolFee1 = poolFee(tokenIn, tokenOut);
        uint24 poolFee2;

        if (poolFee1 == 0) {
            poolFee1 = poolFee(tokenIn, intermediateToken);
            poolFee2 = poolFee(intermediateToken, tokenOut);
            if (poolFee1 == 0 || poolFee2 == 0) {
                revert Skyteller_NoSwapRoute(tokenIn, tokenOut);
            }

            swapOut = uniswapRouter.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(tokenIn, poolFee1, intermediateToken, poolFee2, tokenOut),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum
                })
            );
        } else {
            swapOut = uniswapRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: poolFee1,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: 0 // deactivates this check
                })
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the intermediate token used for multi-pool swaps
    /// @param _intermediateToken The token address
    function setIntermediateToken(address _intermediateToken) public onlyOwner {
        intermediateToken = _intermediateToken;
        emit SetIntermediateToken(address(intermediateToken));
    }

    /// @notice Set the fee recipient for sweeping
    /// @param _skytellerSwapFeeTreasury The fee recipient for sweeping
    function setSkytellerSwapFeeTreasury(address _skytellerSwapFeeTreasury) public onlyOwner {
        skytellerSwapFeeTreasury = _skytellerSwapFeeTreasury;
        emit SetSkytellerSwapFeeTreasury(skytellerSwapFeeTreasury);
    }

    /// @notice Set the fee for sweeping
    /// @dev The fee is denominated in hundredths of a bip, e.g. 1% = 10000
    /// @param _fee The fee for sweeping
    function setSkytellerSwapFee(uint24 _fee) public onlyOwner {
        if (_fee > FEE_PRECISION) {
            revert Skyteller_InvalidFee();
        }
        skytellerSwapFee = _fee;
        emit SetSkytellerSwapFee(skytellerSwapFee);
    }

    /// @notice Set the minimum percent out for swaps
    /// @dev The percent is denominated in bips, e.g. 98.5% = 9850
    /// @param _minimumPercentOutBips The minimum percent out for swaps
    function setMinimumPercentOutBips(uint16 _minimumPercentOutBips) external onlyOwner {
        if (_minimumPercentOutBips > BIPS_PRECISION) {
            revert Skyteller_InvalidPercent();
        }
        minimumPercentOutBips = _minimumPercentOutBips;
        emit SetMinimumPercentOutBips(minimumPercentOutBips);
    }

    /// @notice Set the address of the Uniswap V3 router
    /// @param _uniswapRouter The address of the Uniswap V3 router
    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = ISwapRouter(_uniswapRouter);
        emit SetUniswapRouter(_uniswapRouter);
    }

    /// @notice Set up a token/token/fee configuration to identify
    ///         a Uniswap V3 pool
    /// @dev The fee is denominated in hundredths of a bip, e.g. 0.3% = 3000
    /// @param token0 One of the tokens in the pool
    /// @param token1 The other token in the pool
    /// @param fee The fee of the pool
    function setPool(address token0, address token1, uint24 fee) external onlyOwner {
        if (fee > FEE_PRECISION) {
            revert Skyteller_InvalidFee();
        }
        if (token0 > token1) {
            poolFees[token0][token1] = fee;
            emit SetPool(token0, token1, fee);
        } else {
            poolFees[token1][token0] = fee;
            emit SetPool(token1, token0, fee);
        }
    }

    /// @notice Add a token to the list of supported tokens
    /// @param _token The token to add
    /// @param usdFeed The address of the USD price feed for the token
    /// @param ethFeed The address of the ETH price feed for the token
    /// @param usdPegged Whether the token should be treated as always pegged to USD
    function setTokenPriceFeeds(address _token, address usdFeed, address ethFeed, bool usdPegged)
        external
        onlyOwner
    {
        _tokens.add(_token);
        tokenPriceFeedConfig[_token] =
            TokenPriceFeedConfig({usdPegged: usdPegged, usd: usdFeed, eth: ethFeed});
    }

    /// @notice Remove a token from the list of supported tokens
    function removeToken(address _token) external onlyOwner {
        _tokens.remove(_token);
        delete tokenPriceFeedConfig[_token];
    }

    /// @notice Disable sweeping
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Enable sweeping
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Rescue any ETH sent to this contract

    /**
     * @notice Rescue ERC1155 token balance from the sweeper
     * @param _token The ERC1155 token contract
     * @param tokenId The token ID
     */
    function rescueERC1155(IERC1155 _token, uint256 tokenId) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this), tokenId);
        _token.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit RescueERC1155(address(_token), tokenId, amount);
    }

    /**
     * @notice Rescue ERC721 token from the sweeper
     * @param _token The ERC721 token contract
     * @param tokenId The token ID
     */
    function rescueERC721(IERC721 _token, uint256 tokenId) external onlyOwner {
        _token.safeTransferFrom(address(this), msg.sender, tokenId);
        emit RescueERC721(address(_token), tokenId);
    }

    /**
     * @notice Rescue ERC20 token balance from the sweeper
     * @param _token The ERC20 token contract
     */
    function rescueERC20(IERC20 _token) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, amount);
        emit RescueERC20(address(_token), amount);
    }

    /**
     * @notice Rescue ETH balance from the sweeper
     */
    function rescue() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Rescue(amount);
    }
}