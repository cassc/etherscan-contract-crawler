// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../libraries/Positions.sol";
import "./IManagerBase.sol";
import "./IERC721Extended.sol";

interface IPositionManager is IERC721Extended, IManagerBase {
    /// @notice Mapping of token id to position managed by this contract
    function positionsByTokenId(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint40 pairId,
            uint8 tierId,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Mapping of pair id to its underlying tokens
    function pairs(uint40 pairId) external view returns (address token0, address token1);

    /// @notice Mapping of pool id to pair id
    function pairIdsByPoolId(bytes32 poolId) external view returns (uint40 pairId);

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

    /// @dev Called by hub contract
    function muffinMintCallback(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

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

    /**
     * @notice                  Parameters for the addLiquidity function
     * @param tokenId           Id of the position NFT
     * @param amount0Desired    Desired token0 amount to add to the pool
     * @param amount1Desired    Desired token1 amount to add to the pool
     * @param amount0Min        Minimum token0 amount
     * @param amount1Min        Minimum token1 amount
     * @param useAccount        Use sender's internal account to pay
     */
    struct AddLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        bool useAccount;
    }

    /**
     * @notice              Add liquidity to an existing position
     * @param params        AddLiquidityParams struct
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function addLiquidity(AddLiquidityParams calldata params)
        external
        payable
        returns (
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice                  Parameters for the removeLiquidity function
     * @param tokenId           Id of the position NFT
     * @param liquidityD8       Amount of liquidity to remove (divided by 2^8)
     * @param amount0Min        Minimum token0 amount received from the removed liquidity
     * @param amount1Min        Minimum token1 amount received from the removed liquidity
     * @param withdrawTo        Recipient of the withdrawn tokens. Set to zero for no withdrawal
     * @param collectAllFees    True to collect all remaining accrued fees in the position
     * @param settled           True if the position is settled
     */
    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint96 liquidityD8;
        uint256 amount0Min;
        uint256 amount1Min;
        address withdrawTo;
        bool collectAllFees;
        bool settled;
    }

    /**
     * @notice              Remove liquidity from a position
     * @param params        RemoveLiquidityParams struct
     * @return amount0      Token0 amount from the removed liquidity
     * @return amount1      Token1 amount from the removed liquidity
     * @return feeAmount0   Token0 fee collected from the position
     * @return feeAmount1   Token1 fee collected from the position
     */
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice                 Set position's limit order type
    /// @param tokenId          Id of the position NFT. Or set to zero to indicate the latest NFT id in this contract
    ///                         (useful for chaining this function after `mint` in a multicall)
    /// @param limitOrderType   Direction of limit order (0: N/A, 1: zero->one, 2: one->zero)
    function setLimitOrderType(uint256 tokenId, uint8 limitOrderType) external payable;

    /// @notice             Burn NFTs of empty positions
    /// @param tokenIds     Array of NFT id
    function burn(uint256[] calldata tokenIds) external payable;

    /// @notice             Get the position info of an NFT
    /// @param tokenId      Id of the NFT
    function getPosition(uint256 tokenId)
        external
        view
        returns (
            address owner,
            address token0,
            address token1,
            uint8 tierId,
            int24 tickLower,
            int24 tickUpper,
            Positions.Position memory position
        );
}