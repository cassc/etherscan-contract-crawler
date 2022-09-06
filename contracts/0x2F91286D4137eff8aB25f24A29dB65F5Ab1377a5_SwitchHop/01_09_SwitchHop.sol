// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./interfaces/IHopBridge.sol";
import "./lib/DataTypes.sol";
import "./BaseTrade.sol";

contract SwitchHop is BaseTrade {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    struct TransferArgsHop {
        address fromToken;
        address router;
        address destToken;
        address payable recipient;
        address partner;
        uint256 amount;
        uint256 estimatedDstTokenAmount;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        uint16  dstChainId;
        bytes32 id;
        bytes32 bridge;
    }

    constructor(address _switchEventAddress) BaseTrade(_switchEventAddress) public {

    }

    function transferByHop(TransferArgsHop calldata transferArgs) external payable {
        require(transferArgs.recipient == msg.sender, "The recipient must be equal to caller");
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.fromToken), transferArgs.amount, transferArgs.partner);
        bool isNative = IERC20(transferArgs.fromToken).isETH();
        uint256 value = isNative ? amountAfterFee : 0;
        if (!isNative) {
            // Give hop bridge approval
            uint256 approvedAmount = IERC20(transferArgs.fromToken).allowance(address(this), transferArgs.router);
            if (approvedAmount < amountAfterFee) {
                IERC20(transferArgs.fromToken).safeIncreaseAllowance(transferArgs.router, amountAfterFee - approvedAmount);
            }
        }

        if (block.chainid == 1) {
            // Ethereum L1 -> L2
            IHopBridge(transferArgs.router).sendToL2{ value: value }(
                transferArgs.dstChainId,
                transferArgs.recipient,
                amountAfterFee,
                transferArgs.destinationAmountOutMin,
                transferArgs.destinationDeadline,
                address(0),
                0
            );
        } else {
            // L2 -> L2, L2 -> L1
            require(amountAfterFee >= transferArgs.bonderFee, "Bonder fee cannot exceed amount");
            IHopBridge(transferArgs.router).swapAndSend{ value: value }(
                transferArgs.dstChainId,
                transferArgs.recipient,
                amountAfterFee,
                transferArgs.bonderFee,
                transferArgs.amountOutMin,
                transferArgs.deadline,
                transferArgs.destinationAmountOutMin,
                transferArgs.destinationDeadline
            );
        }

        _emitCrossChainTransferRequest(transferArgs, bytes32(0), amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function _emitCrossChainTransferRequest(TransferArgsHop calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.fromToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            status
        );
    }
}