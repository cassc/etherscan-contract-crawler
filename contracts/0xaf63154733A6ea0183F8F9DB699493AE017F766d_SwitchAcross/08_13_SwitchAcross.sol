// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { IAcrossSpokePool } from "../interfaces/IAcrossSpokePool.sol";
import "../lib/DataTypes.sol";
import "../core/BaseTrade.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwitchAcross is BaseTrade, ReentrancyGuard {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public acrossSpokePool;

    struct TransferArgsAcross {
        address fromToken;
        address destToken;
        address payable recipient;
        address partner;
        uint256 amount;
        uint256 estimatedDstTokenAmount;
        uint256 dstChainId;
        uint64 relayerFeePct;
        uint32 quoteTimestamp;
        bytes32 id;
        bytes32 bridge;
    }

    event AcrossSpokePoolSet(address acrossSpokePool);

    constructor(
        address _switchEventAddress,
        address _acrossSpokePool
    ) BaseTrade(_switchEventAddress)
        public
    {
        acrossSpokePool = _acrossSpokePool;
    }

    function setAcrossSpokePool(address _acrossSpokePool) external onlyOwner {
        acrossSpokePool = _acrossSpokePool;
        emit AcrossSpokePoolSet(_acrossSpokePool);
    }

    function transferByAcross(
        TransferArgsAcross calldata transferArgs
    )
        external
        payable
        nonReentrant
    {
        require(transferArgs.recipient == msg.sender, "The recipient must be equal to caller");
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        address fromToken = transferArgs.fromToken;
        IERC20(fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(fromToken), transferArgs.amount, transferArgs.partner);
        bool isNative = IERC20(fromToken).isETH();

        if (isNative) {
            fromToken = IAcrossSpokePool(acrossSpokePool).wrappedNativeToken();
        } else {
            IERC20(fromToken).universalApprove(acrossSpokePool, amountAfterFee);
        }

        IAcrossSpokePool(acrossSpokePool).deposit{ value: isNative ? amountAfterFee : 0 }(
            transferArgs.recipient,
            fromToken,
            amountAfterFee,
            transferArgs.dstChainId,
            transferArgs.relayerFeePct,
            transferArgs.quoteTimestamp
        );

        _emitCrossChainTransferRequest(
            transferArgs,
            bytes32(0),
            amountAfterFee,
            msg.sender,
            DataTypes.SwapStatus.Succeeded
        );
    }

    function _emitCrossChainTransferRequest(
        TransferArgsAcross calldata transferArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.SwapStatus status
    ) internal {
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