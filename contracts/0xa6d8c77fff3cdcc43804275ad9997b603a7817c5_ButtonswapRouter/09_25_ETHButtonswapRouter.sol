// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IETHButtonswapRouter} from "./interfaces/IButtonswapRouter/IETHButtonswapRouter.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {BasicButtonswapRouter} from "./BasicButtonswapRouter.sol";

contract ETHButtonswapRouter is BasicButtonswapRouter, IETHButtonswapRouter {
    /**
     * @inheritdoc IETHButtonswapRouter
     */
    address public immutable override WETH;

    constructor(address _factory, address _WETH) BasicButtonswapRouter(_factory) {
        WETH = _WETH;
    }

    /**
     * @dev Only accepts ETH via fallback from the WETH contract
     */
    receive() external payable {
        if (msg.sender != WETH) {
            revert NonWETHSender();
        }
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint16 movingAveragePrice0ThresholdBps,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) = _addLiquidity(
            token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin, movingAveragePrice0ThresholdBps
        );
        address pair = ButtonswapLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountToken);
        TransferHelper.safeApprove(token, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        TransferHelper.safeApprove(WETH, pair, amountETH);

        (address token0,) = ButtonswapLibrary.sortTokens(token, WETH);
        liquidity = (token == token0)
            ? IButtonswapPair(pair).mint(amountToken, amountETH, to)
            : IButtonswapPair(pair).mint(amountETH, amountToken, to);

        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function addLiquidityETHWithReservoir(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) =
            _addLiquidityWithReservoir(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = ButtonswapLibrary.pairFor(factory, token, WETH);
        if (amountToken > 0) {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountToken);
            TransferHelper.safeApprove(token, pair, amountToken);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountToken, to);
        } else if (amountETH > 0) {
            IWETH(WETH).deposit{value: amountETH}();
            TransferHelper.safeApprove(WETH, pair, amountETH);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountETH, to);
        }
        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) =
            removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function removeLiquidityETHFromReservoir(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) =
            removeLiquidityFromReservoir(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        if (amountToken > 0) {
            TransferHelper.safeTransfer(token, to, amountToken);
        } else if (amountETH > 0) {
            IWETH(WETH).withdraw(amountETH);
            TransferHelper.safeTransferETH(to, amountETH);
        }
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = ButtonswapLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IButtonswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsOut(factory, msg.value, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }

        IWETH(WETH).deposit{value: amounts[0]}();
        if (!IWETH(WETH).transfer(address(this), amounts[0])) {
            revert FailedWETHTransfer();
        }
        _swap(amounts, path, to);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        if (path[path.length - 1] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) {
            revert ExcessiveInputAmount();
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, address(this));

        // Convert final token to ETH and send to `to`
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        if (path[path.length - 1] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > msg.value) {
            revert ExcessiveInputAmount();
        }

        IWETH(WETH).deposit{value: amounts[0]}();
        if (!IWETH(WETH).transfer(address(this), amounts[0])) {
            revert FailedWETHTransfer();
        }

        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }
}