// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IBasicButtonswapRouter} from "./interfaces/IButtonswapRouter/IBasicButtonswapRouter.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {RootButtonswapRouter} from "./RootButtonswapRouter.sol";

contract BasicButtonswapRouter is RootButtonswapRouter, IBasicButtonswapRouter {
    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert Expired();
        }
        _;
    }

    constructor(address _factory) RootButtonswapRouter(_factory) {}

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint16 movingAveragePrice0ThresholdBps,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, movingAveragePrice0ThresholdBps
        );
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        TransferHelper.safeApprove(tokenA, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        TransferHelper.safeApprove(tokenB, pair, amountB);

        if (tokenA < tokenB) {
            liquidity = IButtonswapPair(pair).mint(amountA, amountB, to);
        } else {
            liquidity = IButtonswapPair(pair).mint(amountB, amountA, to);
        }
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function addLiquidityWithReservoir(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) =
            _addLiquidityWithReservoir(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);

        if (amountA > 0) {
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeApprove(tokenA, pair, amountA);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountA, to);
        } else if (amountB > 0) {
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
            TransferHelper.safeApprove(tokenB, pair, amountB);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountB, to);
        }
    }

    // **** REMOVE LIQUIDITY ****
    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        IButtonswapPair(pair).transferFrom(msg.sender, address(this), liquidity); // send liquidity to router
        (uint256 amount0, uint256 amount1) = IButtonswapPair(pair).burn(liquidity, to);
        (address token0,) = ButtonswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) {
            revert InsufficientAAmount();
        }
        if (amountB < amountBMin) {
            revert InsufficientBAmount();
        }
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function removeLiquidityFromReservoir(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        IButtonswapPair(pair).transferFrom(msg.sender, address(this), liquidity); // send liquidity to router
        (uint256 amount0, uint256 amount1) = IButtonswapPair(pair).burnFromReservoir(liquidity, to);
        (address token0,) = ButtonswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) {
            revert InsufficientAAmount();
        }
        if (amountB < amountBMin) {
            revert InsufficientBAmount();
        }
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IButtonswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    // **** SWAP ****
    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = ButtonswapLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }
        IButtonswapPair(ButtonswapLibrary.pairFor(factory, path[0], path[1]));

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, to);
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) {
            revert ExcessiveInputAmount();
        }
        //        IButtonswapPair pair = IButtonswapPair(ButtonswapLibrary.pairFor(factory, path[0], path[1]));
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, to);
    }
}