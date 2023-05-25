// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@maverick/contracts/contracts/interfaces/IFactory.sol";
import "@maverick/contracts/contracts/interfaces/IPool.sol";
import "@maverick/contracts/contracts/interfaces/IPosition.sol";
import "@maverick/contracts/contracts/interfaces/ISwapCallback.sol";
import "./external/IWETH9.sol";
import "./ISlimRouter.sol";

interface IRouter is ISlimRouter {
    /// @return Returns the address of the factory
    function factory() external view returns (IFactory);

    /// @return Returns the address of the Position NFT
    function position() external view returns (IPosition);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of
    //another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded
    //as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of
    //another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded
    //as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);

    struct PoolParams {
        uint256 fee;
        uint256 tickSpacing;
        int256 lookback;
        int32 activeTick;
        IERC20 tokenA;
        IERC20 tokenB;
    }

    /// @notice create a pool and add liquidity to it
    /// @param poolParams paramters of a pool
    /// @param tokenId nft id of token that will hold lp balance, use 0 to mint a new token
    /// @param addParams paramters of liquidity addition
    /// @param minTokenAAmount minimum amount of token A to add, revert if not met
    /// @param minTokenBAmount minimum amount of token B to add, revert if not met
    /// @param deadline epoch timestamp in seconds
    function getOrCreatePoolAndAddLiquidity(
        PoolParams calldata poolParams,
        uint256 tokenId,
        IPool.AddLiquidityParams[] calldata addParams,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 receivingTokenId,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            IPool.BinDelta[] memory binDeltas
        );

    /// @notice add liquidity to a pool
    /// @param pool pool to add liquidity to
    /// @param tokenId nft id of token that will hold lp balance, use 0 to mint a new token
    /// @param params paramters of liquidity addition
    /// @param minTokenAAmount minimum amount of token A to add, revert if not met
    /// @param minTokenBAmount minimum amount of token B to add, revert if not met
    /// @param deadline epoch timestamp in seconds
    function addLiquidityToPool(
        IPool pool,
        uint256 tokenId,
        IPool.AddLiquidityParams[] calldata params,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 receivingTokenId,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            IPool.BinDelta[] memory binDeltas
        );

    /// @notice add liquidity to a pool with active tick limits
    /// @param pool pool to add liquidity to
    /// @param tokenId nft id of token that will hold lp balance, use 0 to mint a new token
    /// @param params paramters of liquidity addition
    /// @param minTokenAAmount minimum amount of token A to add, revert if not met
    /// @param minTokenBAmount minimum amount of token B to add, revert if not met
    /// @param minActiveTick lowest activeTick (inclusive) of pool that will permit transaction to pass
    /// @param maxActiveTick highest activeTick (inclusive) of pool that will permit transaction to pass
    /// @param deadline epoch timestamp in seconds
    function addLiquidityWTickLimits(
        IPool pool,
        uint256 tokenId,
        IPool.AddLiquidityParams[] calldata params,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount,
        int32 minActiveTick,
        int32 maxActiveTick,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 receivingTokenId,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            IPool.BinDelta[] memory binDeltas
        );

    /// @notice moves the head of input merged bins to the active bin
    /// @param pool to remove from
    /// @param binIds array of bin Ids to migrate
    /// @param maxRecursion maximum recursion depth before returning; 0=no max
    /// @param deadline epoch timestamp in seconds
    function migrateBinsUpStack(
        IPool pool,
        uint128[] calldata binIds,
        uint32 maxRecursion,
        uint256 deadline
    ) external;

    /// @notice remove liquidity from pool and receive WETH if one of the tokens is WETH
    /// @dev router must be approved for the withdrawing tokenId: Position.approve(router, tokenId)
    /// @param pool pool to remove from
    /// @param recipient address where proceeds are sent; use zero or router address to leave tokens in router
    /// @param tokenId ID of position NFT that holds liquidity
    /// @param params paramters of liquidity removal
    /// @param minTokenAAmount minimum amount of token A to receive, revert if not met
    /// @param minTokenBAmount minimum amount of token B to receive, revert if not met
    /// @param deadline epoch timestamp in seconds
    function removeLiquidity(
        IPool pool,
        address recipient,
        uint256 tokenId,
        IPool.RemoveLiquidityParams[] calldata params,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount,
        uint256 deadline
    )
        external
        returns (uint256 tokenAAmount, uint256 tokenBAmount, IPool.BinDelta[] memory binDeltas);
}