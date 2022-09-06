//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IInitialLiquidityVaultEvent1 {

    /// @dev Set BaseInfo, Available only to admin
    /// @param name name
    /// @param token the allocated token address
    /// @param owner  admin address
    event SetBaseInfo(string name, address token, address owner);

    /// @dev Set BoolReadyToCreatePool, Available only to admin
    /// @param boolReadyToCreatePool the flag about ready to create pool
    event SetBoolReadyToCreatePool(bool boolReadyToCreatePool);

    /// @dev Set initial price, Available only to admin
    /// @param tosPrice the tos price
    /// @param tokenPrice the token price
    /// @param initSqrtPrice  initSqrtPrice value
    event SetInitialPrice(uint256 tosPrice, uint256 tokenPrice, uint160 initSqrtPrice);

    event SetStartTime(uint256 _startTime);


    /// @dev Set the uniswap info, Available only to proxy admin
    /// @param poolfactory  UniswapV3Factory address
    /// @param npm  NonfungiblePositionManager address
    event SetUniswapInfo(address poolfactory, address npm);

    /// @dev Set token address, Available only to proxy admin
    /// @param tos  TOS address
    /// @param fee   Pool fee
    /// @param tickSpacings   tick spacings
    event SetTokens(address tos, uint24 fee, int24 tickSpacings);


    /// @dev change the project token address, Available only to admin
    /// @param token  project token address
    event ChangedToken(address token);


    /// @dev Set Pool
    /// @param pool  pool address
    /// @param token0  token0 address
    /// @param token1  token1 address
    event SetPool(address pool, address token0, address token1);


    /// @dev pool initialize with initial price
    /// @param inSqrtPriceX96  project token address
    event SetPoolInitialized(uint160 inSqrtPriceX96);


    /// @dev Emitted when call initialize function. set claim information., Available only to admin
    /// @param _totalAllocatedAmount total allocated amount
    event Initialized(uint256 _totalAllocatedAmount);


    /// @dev Emitted when call mintToken function. Provide liquidity to uniswap V3 and receive LP tokens.
    /// @param caller caller address
    /// @param tokenId tokenId
    /// @param liquidity provide liquidity
    /// @param amount0 Amount of token0 used while increasing liquidity
    /// @param amount1 Amount of token1 used while increasing liquidity
    event MintedInVault(
        address indexed caller,
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    /// @dev Emitted when call withdraw function. If the total allocated amount is all claimed, the remaining token balance can be transferred to the account by the owner.
    /// @param caller caller address
    /// @param tokenAddress token address
    /// @param to account
    /// @param amount amount
    event WithdrawalInVault(address caller, address tokenAddress, address to, uint256 amount);


    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidityInVault(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);


    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event CollectInVault(uint256 indexed tokenId, uint256 amount0, uint256 amount1);

}