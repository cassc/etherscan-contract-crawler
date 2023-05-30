// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {IPosition} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPosition.sol";
import {IFactory} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IFactory.sol";

import {IPoolPositionSlim} from "./IPoolPositionSlim.sol";
import {IReward} from "./IReward.sol";
import {IPoolPositionAndRewardFactorySlim} from "./IPoolPositionAndRewardFactorySlim.sol";
import {IWETH9} from "./external/IWETH9.sol";

interface IPoolPositionManager {
    error InvalidProportion();
    error NotWETH9();
    error PastDeadline(uint256 timestamp, uint256 deadline);
    error EthTransferFailed();
    error InsufficientBalance(address token);
    error NonPoolCaller();
    error NotFactoryPoolPosition();
    error InvalidMinTokenAmount(uint256 tokenAAmount, uint256 minTokenAAmount, uint256 tokenBAmount, uint256 minTokenBAmount);
    error InvalidMinLpAmount(uint256 tokenAmount, uint256 minTokenAmount);
    error InvalidMaxTokenAmount(uint256 tokenAAmount, uint256 maxTokenAAmount, uint256 tokenBAmount, uint256 maxTokenBAmount);

    struct AddLimits {
        uint256 maxTokenAAmount;
        uint256 maxTokenBAmount;
        uint256 deadline;
        bool stakeInReward;
    }
    struct CreateLimits {
        uint256 minTokenAAmount;
        uint256 minTokenBAmount;
        uint256 deadline;
        bool stakeInReward;
    }

    /// @return Returns the address of the factory
    function factory() external view returns (IFactory);

    /// @return Returns the address of the Position NFT
    function position() external view returns (IPosition);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (IWETH9);

    /// @return Returns the address of the PP factory
    function poolPositionFactory() external view returns (IPoolPositionAndRewardFactorySlim);

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(IERC20 token, uint256 amountMinimum, address recipient) external payable;

    /// @notice moves the head of input merged bins to the active bin
    /// @param pool to remove from
    /// @param binIds array of bin Ids to migrate
    /// @param maxRecursion maximum recursion depth before returning; 0=no max
    /// @param deadline epoch timestamp in seconds
    function migrateBinsUpStack(IPool pool, uint128[] calldata binIds, uint32 maxRecursion, uint256 deadline) external payable;

    /// @notice Add liquidity to pool position
    /// @dev manager must be approved for token A/B transfer
    /// @param poolPosition PP to add liquidity to
    /// @param recipient address where PoolPosition erc20 LP tokens are sent
    /// @param desiredLpTokenAmount number of erc20 PP LP tokens to mint
    /// @param minLpTokenAmount miniumum number of erc20 PP LP tokens to mint
    /// @param addLimits struct of max token amounts, deadline and whether to
    //stake new pool position in reward contract
    function addLiquidityToPoolPosition(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 desiredLpTokenAmount,
        uint256 minLpTokenAmount,
        AddLimits calldata addLimits
    ) external payable returns (uint256 mintedPoolPositionTokenAmount, uint256 tokenAAmount, uint256 tokenBAmount);

    /// @notice Add liquidity to pool position with values computed offchain
    /// @dev manager must be approved for token A/B transfer
    /// @param poolPosition PP to add liquidity to
    /// @param recipient address where PoolPosition erc20 LP tokens are sent
    /// @param minLpTokenAmount miniumum number of erc20 PP LP tokens to mint
    /// @param addLimits struct of max token amounts, deadline and whether to
    //stake new pool position in reward contract
    /// @param addParams array of add parameter data
    /// @param bin0LpAmount bin0 LP amount used for minting.  Value minted is
    //the minimum of bin0LpAmount and the amount added to bin zero
    function addLiquidityToPoolPositionWithAddParams(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 minLpTokenAmount,
        AddLimits calldata addLimits,
        IPool.AddLiquidityParams[] memory addParams,
        uint256 bin0LpAmount
    ) external payable returns (uint256 mintedPoolPositionTokenAmount, uint256 tokenAAmount, uint256 tokenBAmount);

    /// @notice Create and Add liquidity to pool position
    /// @dev manager must be approved for token A/B transfer
    /// @param pool factory pool used to create position
    /// @param recipient address where PoolPosition erc20 LP tokens are sent
    /// @param params paramters of liquidity addition
    /// @param isStatic true is all bins in the PP are static
    /// @param createLimits struct of min token amounts, deadline and whether to
    //stake new pool position in reward contract
    function createPoolPositionAndAddLiquidity(
        IPool pool,
        address recipient,
        IPool.AddLiquidityParams[] calldata params,
        bool isStatic,
        CreateLimits calldata createLimits
    ) external payable returns (IPoolPositionSlim poolPosition, uint256 tokenAAmount, uint256 tokenBAmount, IPool.BinDelta[] memory binDeltas, uint256 mintedPoolPositionTokenAmount);

    /// @notice Migrate Pool Position
    /// @dev This needs to be part of an add multicall if the PP bin has been
    //merged
    /// @param poolPosition PP to migrate
    function migrateBinLiquidity(IPoolPositionSlim poolPosition) external payable;

    /// @notice remove liquidity from PP
    /// @dev must approve manager for lpTokenAmount of PP
    /// @param poolPosition PP to add liquidity to
    /// @param recipient address where PoolPosition erc20 LP tokens are sent
    /// @param lpTokenAmount number of erc20 PP LP tokens to remove
    /// @param minTokenAAmount minimum amount of token A to remove, revert if not met
    /// @param minTokenBAmount minimum amount of token B to remove, revert if not met
    /// @param deadline epoch timestamp in seconds
    function removeLiquidityFromPoolPosition(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 lpTokenAmount,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount,
        uint256 deadline
    ) external payable returns (uint256 tokenAAmount, uint256 tokenBAmount);
}