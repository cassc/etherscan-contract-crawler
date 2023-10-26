// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin-solidity/contracts/access/Ownable.sol";
import {IMagpieCelerBridge} from "./interfaces/IMagpieCelerBridge.sol";
import {ILiquidityBridge} from "./interfaces/celer/ILiquidityBridge.sol";
import {IMessageBus} from "./interfaces/celer/IMessageBus.sol";
import {LibAsset} from "./libraries/LibAsset.sol";
import {LibTransferKey, TransferKey} from "./libraries/LibTransferKey.sol";

error CelerBridgeIsNotReady();
error CelerInvalidRefundAddress();

contract MagpieCelerBridge is IMagpieCelerBridge, Ownable {
    using LibAsset for address;
    using LibTransferKey for TransferKey;

    Settings public settings;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => mapping(address => uint256)))) public deposits;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => address))) refundAddresses;

    modifier onlyMagpieAggregator() {
        require(msg.sender == settings.aggregatorAddress);
        _;
    }

    modifier onlyCeler() {
        require(msg.sender == settings.messageBusAddress);
        _;
    }

    function updateSettings(Settings calldata _settings) external onlyOwner {
        settings = _settings;
    }

    function deposit(DepositArgs calldata depositArgs) external payable onlyMagpieAggregator {
        refundAddresses[depositArgs.transferKey.networkId][depositArgs.transferKey.senderAddress][
            depositArgs.transferKey.swapSequence
        ] = depositArgs.sender;

        IMessageBus messageBus = IMessageBus(settings.messageBusAddress);

        address liquidityBridgeAddress = messageBus.liquidityBridge();

        depositArgs.assetAddress.approve(liquidityBridgeAddress, depositArgs.amount);

        ILiquidityBridge(liquidityBridgeAddress).send(
            depositArgs.receiver,
            depositArgs.assetAddress,
            depositArgs.amount,
            depositArgs.chainId,
            depositArgs.transferKey.swapSequence,
            depositArgs.slippage
        );

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                depositArgs.receiver,
                depositArgs.assetAddress,
                depositArgs.amount,
                depositArgs.chainId,
                depositArgs.transferKey.swapSequence,
                uint64(block.chainid)
            )
        );

        messageBus.sendMessageWithTransfer{value: msg.value}(
            depositArgs.receiver,
            depositArgs.chainId,
            liquidityBridgeAddress,
            transferId,
            depositArgs.transferKey.encode()
        );
    }

    function withdraw(WithdrawArgs calldata withdrawArgs) external onlyMagpieAggregator returns (uint256 amount) {
        amount = deposits[withdrawArgs.transferKey.networkId][withdrawArgs.transferKey.senderAddress][
            withdrawArgs.transferKey.swapSequence
        ][withdrawArgs.assetAddress];

        if (amount == 0) {
            revert CelerBridgeIsNotReady();
        }

        deposits[withdrawArgs.transferKey.networkId][withdrawArgs.transferKey.senderAddress][
            withdrawArgs.transferKey.swapSequence
        ][withdrawArgs.assetAddress] = 0;

        withdrawArgs.assetAddress.transfer(settings.aggregatorAddress, amount);
    }

    event Deposit(address indexed assetAddress, uint256 amount, TransferKey transferKey);

    function executeMessageWithTransfer(
        address,
        address assetAddress,
        uint256 amount,
        uint64,
        bytes calldata payload,
        address
    ) external payable override onlyCeler returns (IMessageBus.TxStatus) {
        TransferKey memory transferKey = LibTransferKey.decode(payload);
        deposits[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence][assetAddress] += amount;

        emit Deposit(assetAddress, amount, transferKey);

        return IMessageBus.TxStatus.Success;
    }

    event Refund(address indexed recipient, address indexed assetAddress, uint256 amount, TransferKey transferKey);

    function executeMessageWithTransferRefund(
        address assetAddress,
        uint256 amount,
        bytes calldata payload,
        address
    ) external payable override onlyCeler returns (IMessageBus.TxStatus) {
        TransferKey memory transferKey = LibTransferKey.decode(payload);

        if (refundAddresses[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence] == address(0)) {
            revert CelerInvalidRefundAddress();
        }

        address receiver = refundAddresses[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence];

        assetAddress.transfer(receiver, amount);

        refundAddresses[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence] = address(0);

        emit Refund(receiver, assetAddress, amount, transferKey);

        return IMessageBus.TxStatus.Success;
    }
}