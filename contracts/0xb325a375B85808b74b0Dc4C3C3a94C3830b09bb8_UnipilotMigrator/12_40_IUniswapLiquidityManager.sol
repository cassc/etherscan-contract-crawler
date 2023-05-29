// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IULMEvents.sol";

interface IUniswapLiquidityManager is IULMEvents {
    struct LiquidityPosition {
        // base order position
        int24 baseTickLower;
        int24 baseTickUpper;
        uint128 baseLiquidity;
        // range order position
        int24 rangeTickLower;
        int24 rangeTickUpper;
        uint128 rangeLiquidity;
        // accumulated fees
        uint256 fees0;
        uint256 fees1;
        uint256 feeGrowthGlobal0;
        uint256 feeGrowthGlobal1;
        // total liquidity
        uint256 totalLiquidity;
        // pool premiums
        bool feesInPilot;
        // oracle address for tokens to fetch prices from
        address oracle0;
        address oracle1;
        // rebase
        uint256 timestamp;
        uint8 counter;
        bool status;
        bool managed;
    }

    struct Position {
        uint256 nonce;
        address pool;
        uint256 liquidity;
        uint256 feeGrowth0;
        uint256 feeGrowth1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    struct ReadjustVars {
        bool zeroForOne;
        address poolAddress;
        int24 currentTick;
        uint160 sqrtPriceX96;
        uint160 exactSqrtPriceImpact;
        uint160 sqrtPriceLimitX96;
        uint128 baseLiquidity;
        uint256 amount0;
        uint256 amount1;
        uint256 amountIn;
        uint256 amount0Added;
        uint256 amount1Added;
        uint256 amount0Range;
        uint256 amount1Range;
        uint256 currentTimestamp;
        uint256 gasUsed;
        uint256 pilotAmount;
    }

    struct VarsEmerency {
        address token;
        address pool;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    struct WithdrawVars {
        address recipient;
        uint256 amount0Removed;
        uint256 amount1Removed;
        uint256 userAmount0;
        uint256 userAmount1;
        uint256 pilotAmount;
    }

    struct WithdrawTokenOwedParams {
        address token0;
        address token1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    struct MintCallbackData {
        address payer;
        address token0;
        address token1;
        uint24 fee;
    }

    struct UnipilotProtocolDetails {
        uint8 swapPercentage;
        uint24 swapPriceThreshold;
        uint256 premium;
        uint256 gasPriceLimit;
        uint256 userPilotPercentage;
        uint256 feesPercentageIndexFund;
        uint24 readjustFrequencyTime;
        uint16 poolCardinalityDesired;
        address pilotWethPair;
        address oracle;
        address indexFund; // 10%
        address uniStrategy;
        address unipilot;
    }

    struct SwapCallbackData {
        address token0;
        address token1;
        uint24 fee;
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    struct RemoveLiquidity {
        uint256 amount0;
        uint256 amount1;
        uint128 liquidityRemoved;
        uint256 feesCollected0;
        uint256 feesCollected1;
    }

    struct Tick {
        int24 baseTickLower;
        int24 baseTickUpper;
        int24 bidTickLower;
        int24 bidTickUpper;
        int24 rangeTickLower;
        int24 rangeTickUpper;
    }

    struct TokenDetails {
        address token0;
        address token1;
        uint24 fee;
        int24 currentTick;
        uint16 poolCardinality;
        uint128 baseLiquidity;
        uint128 bidLiquidity;
        uint128 rangeLiquidity;
        uint256 amount0Added;
        uint256 amount1Added;
    }

    struct DistributeFeesParams {
        bool pilotToken;
        bool wethToken;
        address pool;
        address recipient;
        uint256 tokenId;
        uint256 liquidity;
        uint256 amount0Removed;
        uint256 amount1Removed;
    }

    struct AddLiquidityManagerParams {
        address pool;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 shares;
    }

    struct DepositVars {
        uint24 fee;
        address pool;
        uint256 amount0Base;
        uint256 amount1Base;
        uint256 amount0Range;
        uint256 amount1Range;
    }

    struct RangeLiquidityVars {
        address token0;
        address token1;
        uint24 fee;
        uint128 rangeLiquidity;
        uint256 amount0Range;
        uint256 amount1Range;
    }

    struct IncreaseParams {
        address token0;
        address token1;
        uint24 fee;
        int24 currentTick;
        uint128 baseLiquidity;
        uint256 baseAmount0;
        uint256 baseAmount1;
        uint128 rangeLiquidity;
        uint256 rangeAmount0;
        uint256 rangeAmount1;
    }

    /// @notice Pull in tokens from sender. Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay to the pool for the minted liquidity.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;

    /// @notice Called to `msg.sender` after minting swaping from IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay to the pool for swap.
    /// @param amount0Delta The amount of token0 due to the pool for the swap
    /// @param amount1Delta The amount of token1 due to the pool for the swap
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;

    /// @notice Returns the user position information associated with a given token ID.
    /// @param tokenId The ID of the token that represents the position
    /// @return Position
    /// - nonce The nonce for permits
    /// - pool Address of the uniswap V3 pool
    /// - liquidity The liquidity of the position
    /// - feeGrowth0 The fee growth of token0 as of the last action on the individual position
    /// - feeGrowth1 The fee growth of token1 as of the last action on the individual position
    /// - tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// - tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function userPositions(uint256 tokenId)
        external
        view
        returns (Position memory);

    /// @notice Returns the vault information of unipilot base & range orders
    /// @param pool Address of the Uniswap pool
    /// @return LiquidityPosition
    /// - baseTickLower The lower tick of the base position
    /// - baseTickUpper The upper tick of the base position
    /// - baseLiquidity The total liquidity of the base position
    /// - rangeTickLower The lower tick of the range position
    /// - rangeTickUpper The upper tick of the range position
    /// - rangeLiquidity The total liquidity of the range position
    /// - fees0 Total amount of fees collected by unipilot positions in terms of token0
    /// - fees1 Total amount of fees collected by unipilot positions in terms of token1
    /// - feeGrowthGlobal0 The fee growth of token0 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// - feeGrowthGlobal1 The fee growth of token1 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// - totalLiquidity Total amount of liquidity of vault including base & range orders
    function poolPositions(address pool)
        external
        view
        returns (LiquidityPosition memory);

    /// @notice Calculates the vault's total holdings of token0 and token1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @param _pool Address of the uniswap pool
    /// @return amount0 Total amount of token0 in vault
    /// @return amount1 Total amount of token1 in vault
    /// @return totalLiquidity Total liquidity of the vault
    function updatePositionTotalAmounts(address _pool)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        );

    /// @notice Calculates the vault's total holdings of TOKEN0 and TOKEN1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @dev Updates the position and return the latest reserves & liquidity.
    /// @param token0 token0 of the pool
    /// @param token0 token1 of the pool
    /// @param data any necessary data needed to get reserves
    /// @return totalAmount0 Amount of token0 in the pool of unipilot
    /// @return totalAmount1 Amount of token1 in the pool of unipilot
    /// @return totalLiquidity Total liquidity available in unipilot pool
    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        returns (
            uint256 totalAmount0,
            uint256 totalAmount1,
            uint256 totalLiquidity
        );

    /// @notice Creates a new pool & then initializes the pool
    /// @param _token0 The contract address of token0 of the pool
    /// @param _token1 The contract address of token1 of the pool
    /// @param data Necessary data needed to create pool
    /// In data we will provide the `fee` amount of the v3 pool for the specified token pair,
    /// also `sqrtPriceX96` The initial square root price of the pool
    /// @return _pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address
    function createPair(
        address _token0,
        address _token1,
        bytes memory data
    ) external returns (address _pool);

    /// @notice Deposits tokens in proportion to the Unipilot's current ticks, mints them
    /// `Unipilot`s NFT.
    /// @param token0 The first of the two tokens of the pool, sorted by address
    /// @param token1 The second of the two tokens of the pool, sorted by address
    /// @param amount0Desired Max amount of token0 to deposit
    /// @param amount1Desired Max amount of token1 to deposit
    /// @param shares Number of shares minted
    /// @param tokenId Token Id of Unipilot
    /// @param isTokenMinted Boolean to check the minting of new tokenId of Unipilot
    /// @param data Necessary data needed to deposit
    function deposit(
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes memory data
    ) external payable;

    /// @notice withdraws the desired shares from the vault with accumulated user fees and transfers to recipient.
    /// @param pilotToken whether to recieve fees in PILOT or not (valid if user is not reciving fees in token0, token1)
    /// @param wethToken whether to recieve fees in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param liquidity The amount by which liquidity will be withdrawn
    /// @param tokenId The ID of the token for which liquidity is being withdrawn
    /// @param data Necessary data needed to withdraw liquidity from Unipilot
    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    /// @notice Collects up to a maximum amount of fees owed to a specific user position to the recipient
    /// @dev User have both options whether to recieve fees in PILOT or in pool token0 & token1
    /// @param pilotToken whether to recieve fees in PILOT or not (valid if user is not reciving fees in token0, token1)
    /// @param wethToken whether to recieve fees in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param tokenId The ID of the Unpilot NFT for which tokens will be collected
    /// @param data Necessary data needed to collect fees from Unipilot
    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes memory data
    ) external payable;
}