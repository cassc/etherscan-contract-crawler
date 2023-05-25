// SPDX-License-Identifier: GPL-2.0-or-later
// inspired by https://github.com/Uniswap/v3-periphery
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {IPosition} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPosition.sol";
import {IFactory} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IFactory.sol";

import {IPoolPositionSlim} from "./interfaces/IPoolPositionSlim.sol";
import {IReward} from "./interfaces/IReward.sol";
import {IPoolPositionAndRewardFactorySlim} from "./interfaces/IPoolPositionAndRewardFactorySlim.sol";

import {IPoolPositionManager} from "./interfaces/IPoolPositionManager.sol";
import {IWETH9} from "./interfaces/external/IWETH9.sol";
import {PoolPositionUtilities} from "./libraries/PoolPositionUtilities.sol";
import {Multicall} from "./libraries/Multicall.sol";

contract PoolPositionManager is IPoolPositionManager, ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;
    uint256 constant ONE = 1e18;
    uint256 public managerTokenId;

    struct AddLiquidityCallbackData {
        address payer;
    }

    IFactory public immutable factory;
    IPosition public immutable position;
    IWETH9 public immutable WETH9;
    IPoolPositionAndRewardFactorySlim public immutable poolPositionFactory;

    constructor(IWETH9 _WETH9, IPoolPositionAndRewardFactorySlim _poolPositionFactory) {
        factory = _poolPositionFactory.poolFactory();
        position = factory.position();
        WETH9 = _WETH9;
        poolPositionFactory = _poolPositionFactory;
        managerTokenId = position.mint(address(this));
    }

    receive() external payable {
        if (IWETH9(msg.sender) != WETH9) revert NotWETH9();
    }

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert PastDeadline(block.timestamp, deadline);
        _;
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override nonReentrant {
        uint256 balanceWETH9 = WETH9.balanceOf(address(this));
        if (balanceWETH9 < amountMinimum) revert InsufficientBalance(address(WETH9));

        if (balanceWETH9 != 0) {
            WETH9.withdraw(balanceWETH9);
            _safeTransferETH(recipient, balanceWETH9);
        }
    }

    function sweepToken(IERC20 token, uint256 amountMinimum, address recipient) public payable nonReentrant {
        uint256 balanceToken = token.balanceOf(address(this));
        if (balanceToken < amountMinimum) revert InsufficientBalance(address(token));

        if (balanceToken != 0) {
            token.safeTransfer(recipient, balanceToken);
        }
    }

    function refundETH() external payable override nonReentrant {
        if (address(this).balance != 0) _safeTransferETH(msg.sender, address(this).balance);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function _pay(IERC20 token, address payer, address recipient, uint256 value) internal nonReentrant {
        if (IWETH9(address(token)) == WETH9 && address(this).balance >= value) {
            WETH9.deposit{value: value}();
            WETH9.transfer(recipient, value);
        } else if (payer == address(this)) {
            token.safeTransfer(recipient, value);
        } else {
            token.safeTransferFrom(payer, recipient, value);
        }
    }

    // Liqudity

    function addLiquidityCallback(uint256 amountA, uint256 amountB, bytes calldata _data) external {
        AddLiquidityCallbackData memory data = abi.decode(_data, (AddLiquidityCallbackData));
        IPool pool = IPool(msg.sender);
        if (!factory.isFactoryPool(pool)) revert NonPoolCaller();
        if (amountA != 0) {
            _pay(pool.tokenA(), data.payer, msg.sender, amountA);
        }
        if (amountB != 0) {
            _pay(pool.tokenB(), data.payer, msg.sender, amountB);
        }
    }

    function _addLiquidity(
        IPool pool,
        uint256 tokenId,
        IPool.AddLiquidityParams[] memory params,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount
    ) private returns (uint256 receivingTokenId, uint256 tokenAAmount, uint256 tokenBAmount, IPool.BinDelta[] memory binDeltas) {
        receivingTokenId = tokenId;

        AddLiquidityCallbackData memory data = AddLiquidityCallbackData({payer: msg.sender});
        (tokenAAmount, tokenBAmount, binDeltas) = pool.addLiquidity(tokenId, params, abi.encode(data));

        if (tokenAAmount < minTokenAAmount || tokenBAmount < minTokenBAmount) revert InvalidMinTokenAmount(tokenAAmount, minTokenAAmount, tokenBAmount, minTokenBAmount);
    }

    function migrateBinsUpStack(IPool pool, uint128[] calldata binIds, uint32 maxRecursion, uint256 deadline) external payable checkDeadline(deadline) {
        uint256 binsLength = binIds.length;
        for (uint256 i; i < binsLength; i++) {
            pool.migrateBinUpStack(binIds[i], maxRecursion);
        }
    }

    ///////////  PoolPosition

    function _createPoolPositionFromDeltas(IPool pool, IPool.BinDelta[] memory binDeltas, bool isStatic) private returns (IPoolPositionSlim poolPosition) {
        uint256 length = binDeltas.length;
        uint128[] memory binIds = new uint128[](length);
        uint128[] memory ratios = new uint128[](length);
        uint256 firstBinLpBalance = binDeltas[0].deltaLpBalance;
        IPool.BinDelta memory binDelta;

        uint128 lastBinId = 0;
        for (uint256 i; i < length; i++) {
            binDelta = binDeltas[i];
            binIds[i] = binDelta.binId;
            if (!(binIds[i] > lastBinId)) revert IPoolPositionSlim.InvalidBinIds(binIds);
            ratios[i] = SafeCast.toUint128(Math.mulDiv(binDelta.deltaLpBalance, ONE, firstBinLpBalance));
        }
        poolPosition = poolPositionFactory.createPoolPositionAndRewards(pool, binIds, ratios, isStatic);
    }

    /// @dev we can approve the PP because we have validated that it is a
    //factory PP
    function _mintPoolPosition(IPoolPositionSlim poolPosition, address recipient, uint256 bin0LpAmount) private returns (uint256 mintedPoolPositionTokenAmount) {
        uint256 _managerTokenId = managerTokenId;

        position.approve(address(poolPosition), _managerTokenId);

        mintedPoolPositionTokenAmount = poolPosition.mint(recipient, _managerTokenId, SafeCast.toUint128(bin0LpAmount));
        position.approve(address(0), _managerTokenId);
    }

    function createPoolPositionAndAddLiquidity(
        IPool pool,
        address recipient,
        IPool.AddLiquidityParams[] calldata params,
        bool isStatic,
        CreateLimits calldata createLimits
    )
        external
        payable
        checkDeadline(createLimits.deadline)
        returns (IPoolPositionSlim poolPosition, uint256 tokenAAmount, uint256 tokenBAmount, IPool.BinDelta[] memory binDeltas, uint256 mintedPoolPositionTokenAmount)
    {
        (, tokenAAmount, tokenBAmount, binDeltas) = _addLiquidity(pool, managerTokenId, params, createLimits.minTokenAAmount, createLimits.minTokenBAmount);
        poolPosition = _createPoolPositionFromDeltas(pool, binDeltas, isStatic);
        mintedPoolPositionTokenAmount = _mintPoolPosition(poolPosition, createLimits.stakeInReward ? address(this) : recipient, binDeltas[0].deltaLpBalance);

        if (createLimits.stakeInReward) {
            _stakeLpTokensInReward(poolPosition, recipient, mintedPoolPositionTokenAmount);
        }
    }

    function _stakeLpTokensInReward(IPoolPositionSlim poolPosition, address recipient, uint256 amountToStake) internal {
        IReward lpReward = poolPositionFactory.getLpRewardByPP(poolPosition);
        poolPosition.approve(address(lpReward), amountToStake);
        lpReward.stake(amountToStake, recipient);
    }

    function migrateBinLiquidity(IPoolPositionSlim poolPosition) external payable {
        poolPosition.migrateBinLiquidity();
    }

    function getAddLiquidityParams(IPool pool, IPoolPositionSlim poolPosition, uint256 lpTokenAmount) external view returns (IPool.AddLiquidityParams[] memory addParams, uint256 bin0LpAmount) {
        (addParams, bin0LpAmount) = PoolPositionUtilities.getAddLiquidityParams(pool, poolPosition, lpTokenAmount);
    }

    function _addLiquidityToPoolPosition(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 minLpTokenAmount,
        AddLimits calldata addLimits,
        IPool.AddLiquidityParams[] memory addParams,
        uint256 bin0LpAmount,
        IPool pool
    ) internal returns (uint256 mintedPoolPositionTokenAmount, uint256 tokenAAmount, uint256 tokenBAmount) {
        IPool.BinDelta[] memory binDeltas;
        (, tokenAAmount, tokenBAmount, binDeltas) = _addLiquidity(pool, managerTokenId, addParams, 0, 0);
        if (tokenAAmount > addLimits.maxTokenAAmount || tokenBAmount > addLimits.maxTokenBAmount)
            revert InvalidMaxTokenAmount(tokenAAmount, addLimits.maxTokenAAmount, tokenBAmount, addLimits.maxTokenBAmount);

        bin0LpAmount = Math.min(bin0LpAmount, binDeltas[0].deltaLpBalance);

        mintedPoolPositionTokenAmount = _mintPoolPosition(poolPosition, addLimits.stakeInReward ? address(this) : recipient, bin0LpAmount);

        if (mintedPoolPositionTokenAmount < minLpTokenAmount) revert InvalidMinLpAmount(mintedPoolPositionTokenAmount, minLpTokenAmount);

        if (addLimits.stakeInReward) {
            _stakeLpTokensInReward(poolPosition, recipient, mintedPoolPositionTokenAmount);
        }
    }

    function addLiquidityToPoolPositionWithAddParams(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 minLpTokenAmount,
        AddLimits calldata addLimits,
        IPool.AddLiquidityParams[] memory addParams,
        uint256 bin0LpAmount
    ) external payable checkDeadline(addLimits.deadline) returns (uint256 mintedPoolPositionTokenAmount, uint256 tokenAAmount, uint256 tokenBAmount) {
        if (!poolPositionFactory.isPoolPosition(poolPosition)) revert NotFactoryPoolPosition();
        IPool pool = poolPosition.pool();
        (mintedPoolPositionTokenAmount, tokenAAmount, tokenBAmount) = _addLiquidityToPoolPosition(poolPosition, recipient, minLpTokenAmount, addLimits, addParams, bin0LpAmount, pool);
    }

    function addLiquidityToPoolPosition(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 desiredLpTokenAmount,
        uint256 minLpTokenAmount,
        AddLimits calldata addLimits
    ) external payable checkDeadline(addLimits.deadline) returns (uint256 mintedPoolPositionTokenAmount, uint256 tokenAAmount, uint256 tokenBAmount) {
        if (!poolPositionFactory.isPoolPosition(poolPosition)) revert NotFactoryPoolPosition();
        IPool pool = poolPosition.pool();
        (IPool.AddLiquidityParams[] memory addParams, uint256 bin0LpAmount) = PoolPositionUtilities.getAddLiquidityParams(pool, poolPosition, desiredLpTokenAmount);
        (mintedPoolPositionTokenAmount, tokenAAmount, tokenBAmount) = _addLiquidityToPoolPosition(poolPosition, recipient, minLpTokenAmount, addLimits, addParams, bin0LpAmount, pool);
    }

    function removeLiquidityFromPoolPosition(
        IPoolPositionSlim poolPosition,
        address recipient,
        uint256 lpTokenAmount,
        uint256 minTokenAAmount,
        uint256 minTokenBAmount,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (tokenAAmount, tokenBAmount) = poolPosition.burnFromToAddressAsReserves(msg.sender, recipient, lpTokenAmount);
        if (tokenAAmount < minTokenAAmount || tokenBAmount < minTokenBAmount) revert InvalidMinTokenAmount(tokenAAmount, minTokenAAmount, tokenBAmount, minTokenBAmount);
    }
}