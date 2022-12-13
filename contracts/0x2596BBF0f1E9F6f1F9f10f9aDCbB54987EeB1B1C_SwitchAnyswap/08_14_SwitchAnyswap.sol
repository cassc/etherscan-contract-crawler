// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { IAnyswapV4Router } from "../interfaces/IAnyswapV4Router.sol";
import { IAnyswapToken } from "../interfaces/IAnyswapToken.sol";
import "../lib/DataTypes.sol";
import "../core/BaseTrade.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwitchAnyswap is BaseTrade, ReentrancyGuard {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public anyswapRouter;

    struct TransferArgsAnyswap {
        address fromToken;
        address bridgeToken;
        address destToken;
        address payable recipient;
        uint256 amount;
        uint256 estimatedDstTokenAmount;
        uint16  dstChainId;
        bytes32 id;
        bytes32 bridge;
        address partner;
    }

    event AnyswapRouterSet(address anyswapRouter);

    constructor(
        address _switchEventAddress,
        address _anyswapRouter
    ) BaseTrade(_switchEventAddress)
        public
    {
        anyswapRouter = _anyswapRouter;
    }

    function setAnyswapRouter(address _anyswapRouter) external onlyOwner {
        anyswapRouter = _anyswapRouter;
        emit AnyswapRouterSet(_anyswapRouter);
    }

    function transferByAnyswap(
        TransferArgsAnyswap calldata transferArgs
    )
        external
        payable
        nonReentrant
    {
        require(transferArgs.recipient == msg.sender, "The recipient must be equal to caller");
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        // Multichain (formerly Anyswap) tokens can wrap other tokens
        (address underlyingToken, bool isNative) = _getUnderlyingToken(transferArgs.bridgeToken, anyswapRouter);

        IERC20(underlyingToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(underlyingToken), transferArgs.amount, transferArgs.partner);

        if (isNative) {
            IAnyswapV4Router(anyswapRouter).anySwapOutNative{ value: amountAfterFee }(
                transferArgs.bridgeToken,
                transferArgs.recipient,
                transferArgs.dstChainId
            );
        } else {
            // Give Anyswap approval to bridge tokens
            uint256 approvedAmount = IERC20(underlyingToken).allowance(address(this), anyswapRouter);
            if (approvedAmount < amountAfterFee) {
                IERC20(underlyingToken).safeIncreaseAllowance(anyswapRouter, amountAfterFee - approvedAmount);
            }
            // Was the token wrapping another token?
            if (transferArgs.bridgeToken != underlyingToken) {
                IAnyswapV4Router(anyswapRouter).anySwapOutUnderlying(
                    transferArgs.bridgeToken,
                    transferArgs.recipient,
                    amountAfterFee,
                    transferArgs.dstChainId
                );
            } else {
                IAnyswapV4Router(anyswapRouter).anySwapOut(
                    transferArgs.bridgeToken,
                    transferArgs.recipient,
                    amountAfterFee,
                    transferArgs.dstChainId
                );
            }
        }

        _emitCrossChainTransferRequest(transferArgs, bytes32(0), amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function _getUnderlyingToken(
        address token,
        address router
    )
        private
        returns (address underlyingToken, bool isNative)
    {
        // Token must implement IAnyswapToken interface
        require(token != address (0), 'Token address should not be zero');
        underlyingToken = IAnyswapToken(token).underlying();
        // The native token does not use the standard null address ID
        isNative = IAnyswapV4Router(router).wNATIVE() == underlyingToken;
        // Some Multichain complying tokens may wrap nothing
        if (!isNative && underlyingToken == address(0)) {
            underlyingToken = token;
        }
    }

    function _emitCrossChainTransferRequest(TransferArgsAnyswap calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.bridgeToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            status
        );
    }
}