// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../lib/DataTypes.sol";
import "../core/BaseTrade.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IDeBridgeGate.sol";

contract SwitchDeBridge is BaseTrade, ReentrancyGuard {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public deBridgeGate;

    struct TransferArgsDeBridge {
        address fromToken;
        address destToken;
        address payable recipient;
        address partner;
        uint256 amount;
        uint256 nativeFee;
        uint256 estimatedDstTokenAmount;
        uint256 dstChainId;
        bool useAssetFee;
        uint32 referralCode;
        bytes32 id;
        bytes32 bridge;
        bytes permit;
        bytes autoParams;
    }

    event DeBridgeGateSet(address deBridgeGate);

    constructor(
        address _switchEventAddress,
        address _deBridgeGate
    ) BaseTrade(_switchEventAddress)
        public
    {
        deBridgeGate = _deBridgeGate;
    }

    function setDeBridgeGate(address _deBridgeGate) external onlyOwner {
        deBridgeGate = _deBridgeGate;
        emit DeBridgeGateSet(_deBridgeGate);
    }

    function transferByDeBridge(
        TransferArgsDeBridge calldata transferArgs
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
        uint256 nativeAssetAmount = 0;

        if (isNative) {
            nativeAssetAmount = amountAfterFee;
        } else {
            nativeAssetAmount = transferArgs.nativeFee;
            IERC20(fromToken).universalApprove(deBridgeGate, amountAfterFee);
        }

        require(msg.value >= nativeAssetAmount, 'native token is not enough');
        IDeBridgeGate(deBridgeGate).send{ value: nativeAssetAmount }(
            fromToken,
            amountAfterFee,
            transferArgs.dstChainId,
            abi.encodePacked(transferArgs.recipient),
            transferArgs.permit,
            transferArgs.useAssetFee,
            transferArgs.referralCode,
            transferArgs.autoParams
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
        TransferArgsDeBridge calldata transferArgs,
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