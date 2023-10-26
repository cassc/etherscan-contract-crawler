// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMessageBus} from "../interfaces/celer/IMessageBus.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";

interface IMagpieCelerBridge {
    struct Settings {
        address aggregatorAddress;
        address messageBusAddress;
    }

    function updateSettings(Settings calldata _settings) external;

    struct DepositArgs {
        uint32 slippage;
        uint64 chainId;
        uint256 amount;
        address sender;
        address receiver;
        address assetAddress;
        TransferKey transferKey;
    }

    function deposit(DepositArgs calldata depositArgs) external payable;

    struct WithdrawArgs {
        address assetAddress;
        TransferKey transferKey;
    }

    function withdraw(WithdrawArgs calldata withdrawArgs) external returns (uint256 amountOut);

    function executeMessageWithTransfer(
        address,
        address assetAddress,
        uint256 amount,
        uint64,
        bytes calldata payload,
        address
    ) external payable returns (IMessageBus.TxStatus);

    function executeMessageWithTransferRefund(
        address assetAddress,
        uint256 amount,
        bytes calldata message,
        address
    ) external payable returns (IMessageBus.TxStatus);
}