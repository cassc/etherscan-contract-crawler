// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IManagerMinimal {
    function WETH9() external view returns (address);

    /// @notice             Create a pool for token0 and token1 if it hasn't been created
    /// @dev                DO NOT create pool with rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param sqrtPrice    Sqrt price of token0 denominated in token1
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        bool useAccount
    ) external payable;

    /// @notice             Add a tier to a pool
    /// @dev                This function is subject to sandwitch attack which costs more tokens to add a tier, but the extra cost
    ///                     should be small in common token pairs. Also, users can multicall with "mint" to do slippage check.
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param expectedTierId Expected id of the new tier. Revert if unmatched. Set to type(uint8).max for skipping the check.
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        bool useAccount,
        uint8 expectedTierId
    ) external payable;

    /**
     * @notice                  Parameters for the mint function
     * @param token0            Address of token0 of the pool
     * @param token1            Address of token1 of the pool
     * @param tierId            Position's tier index
     * @param tickLower         Position's lower tick boundary
     * @param tickUpper         Position's upper tick boundary
     * @param amount0Desired    Desired token0 amount to add to the pool
     * @param amount1Desired    Desired token1 amount to add to the pool
     * @param amount0Min        Minimum token0 amount
     * @param amount1Min        Minimum token1 amount
     * @param recipient         Recipient of the position token
     * @param useAccount        Use sender's internal account to pay
     */
    struct MintParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        bool useAccount;
    }

    /**
     * @notice              Mint a position NFT
     * @param params        MintParams struct
     * @return tokenId      Id of the NFT
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        );
}