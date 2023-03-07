// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {InvalidAmountIn, LibRouter, SwapArgs} from "../router/LibRouter.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {LibBridge, BridgeArgs} from "../bridge/LibBridge.sol";
import {LibTransaction, Transaction, TransactionValidation} from "../bridge/LibTransaction.sol";
import {DataTransferInArgs, DataTransferInProtocol, DataTransferOutArgs, LibDataTransfer, TransferKey} from "../data-transfer/LibDataTransfer.sol";
import "../libraries/LibError.sol";

struct SwapInArgs {
    SwapArgs swapArgs;
    BridgeArgs bridgeArgs;
    DataTransferInProtocol dataTransferInProtocol;
    TransactionValidation transactionValidation;
}

struct SwapOutArgs {
    SwapArgs swapArgs;
    BridgeArgs bridgeArgs;
    DataTransferOutArgs dataTransferOutArgs;
}

struct SwapOutVariables {
    address fromAssetAddress;
    address toAssetAddress;
    address toAddress;
    address transactionToAddress;
    uint256 bridgeAmount;
    uint256 amountIn;
}

library LibAggregator {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    event UpdateWeth(address indexed sender, address weth);

    function updateWeth(address weth) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.weth = weth;

        emit UpdateWeth(msg.sender, weth);
    }

    event UpdateNetworkId(address indexed sender, uint16 networkId);

    function updateNetworkId(uint16 networkId) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.networkId = networkId;

        emit UpdateNetworkId(msg.sender, networkId);
    }

    event AddMagpieAggregatorAddresses(
        address indexed sender,
        uint16[] networkIds,
        bytes32[] magpieAggregatorAddresses
    );

    function addMagpieAggregatorAddresses(uint16[] memory networkIds, bytes32[] memory magpieAggregatorAddresses)
        internal
    {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = magpieAggregatorAddresses.length;
        for (i = 0; i < l; ) {
            s.magpieAggregatorAddresses[networkIds[i]] = magpieAggregatorAddresses[i];

            unchecked {
                i++;
            }
        }

        emit AddMagpieAggregatorAddresses(msg.sender, networkIds, magpieAggregatorAddresses);
    }

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    function swap(SwapArgs memory swapArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        address toAddress = swapArgs.addresses.toAddress(0);
        address fromAssetAddress = swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapArgs.addresses.toAddress(40);
        uint256 amountIn = swapArgs.amountIns.sum();

        fromAssetAddress.deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapArgs);

        toAssetAddress.withdraw(s.weth, swapArgs.addresses.toAddress(0), amountOut);

        emit Swap(msg.sender, toAddress, fromAssetAddress, toAssetAddress, amountIn, amountOut);
    }

    event SwapIn(
        address indexed fromAddress,
        bytes32 indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapIn(SwapInArgs memory swapInArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (swapInArgs.swapArgs.addresses.toAddress(0) != address(this)) {
            revert InvalidToAddress();
        }

        uint256 amountIn = swapInArgs.swapArgs.amountIns.sum();
        address fromAssetAddress = swapInArgs.swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapInArgs.swapArgs.addresses.toAddress(40);

        fromAssetAddress.deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapInArgs.swapArgs);

        uint64 tokenSequence = LibBridge.bridgeIn(
            swapInArgs.bridgeArgs,
            swapInArgs.transactionValidation,
            amountOut,
            toAssetAddress
        );

        Transaction memory transaction = Transaction({
            bridgeType: swapInArgs.bridgeArgs.bridgeType,
            fromAssetAddress: swapInArgs.transactionValidation.fromAssetAddress,
            toAssetAddress: swapInArgs.transactionValidation.toAssetAddress,
            toAddress: swapInArgs.transactionValidation.toAddress,
            recipientAggregatorAddress: swapInArgs.transactionValidation.recipientAggregatorAddress,
            amountOutMin: swapInArgs.transactionValidation.amountOutMin,
            swapOutGasFee: swapInArgs.transactionValidation.swapOutGasFee,
            tokenSequence: tokenSequence
        });

        DataTransferInProtocol[] memory protocols = new DataTransferInProtocol[](1);
        protocols[0] = swapInArgs.dataTransferInProtocol;

        TransferKey memory transferKey = LibDataTransfer.dataTransfer(
            DataTransferInArgs({protocols: protocols, payload: LibTransaction.encode(transaction)})
        );

        emit SwapIn(
            msg.sender,
            transaction.toAddress,
            fromAssetAddress,
            toAssetAddress,
            amountIn,
            amountOut,
            transferKey,
            transaction
        );
    }

    event SwapOut(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapOut(SwapOutArgs memory swapOutArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        (TransferKey memory transferKey, bytes memory payload) = LibDataTransfer.getPayload(
            swapOutArgs.dataTransferOutArgs
        );

        if (s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.coreSequence]) {
            revert InvalidTransferKey();
        }

        s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.coreSequence] = true;

        Transaction memory transaction = LibTransaction.decode(payload);

        SwapOutVariables memory v = SwapOutVariables({
            bridgeAmount: LibBridge.bridgeOut(swapOutArgs.bridgeArgs, transaction, transferKey),
            amountIn: swapOutArgs.swapArgs.amountIns.sum(),
            toAddress: swapOutArgs.swapArgs.addresses.toAddress(0),
            transactionToAddress: address(uint160(uint256(transaction.toAddress))),
            fromAssetAddress: swapOutArgs.swapArgs.addresses.toAddress(20),
            toAssetAddress: swapOutArgs.swapArgs.addresses.toAddress(40)
        });

        if (v.transactionToAddress == msg.sender) {
            transaction.swapOutGasFee = 0;
            transaction.amountOutMin = swapOutArgs.swapArgs.amountOutMin;
        } else {
            swapOutArgs.swapArgs.amountOutMin = transaction.amountOutMin;
        }

        if (address(uint160(uint256(transaction.fromAssetAddress))) != v.fromAssetAddress) {
            revert InvalidFromAssetAddress();
        }

        if (msg.sender != v.transactionToAddress) {
            if (address(uint160(uint256(transaction.toAssetAddress))) != v.toAssetAddress) {
                revert InvalidToAssetAddress();
            }
        }

        if (v.transactionToAddress != v.toAddress || v.transactionToAddress == address(this)) {
            revert InvalidToAddress();
        }

        if (address(uint160(uint256(transaction.recipientAggregatorAddress))) != address(this)) {
            revert InvalidMagpieAggregatorAddress();
        }

        if (swapOutArgs.swapArgs.amountOutMin < transaction.amountOutMin) {
            revert InvalidAmountOutMin();
        }

        if (swapOutArgs.swapArgs.amountIns[0] <= transaction.swapOutGasFee) {
            revert InvalidAmountIn();
        }

        if (v.amountIn > v.bridgeAmount) {
            revert InvalidAmountIn();
        }

        swapOutArgs.swapArgs.amountIns[0] =
            swapOutArgs.swapArgs.amountIns[0] +
            (v.bridgeAmount > v.amountIn ? v.bridgeAmount - v.amountIn : 0) -
            transaction.swapOutGasFee;
        v.amountIn = swapOutArgs.swapArgs.amountIns.sum();

        amountOut = LibRouter.swap(swapOutArgs.swapArgs);

        if (transaction.swapOutGasFee > 0) {
            s.deposits[v.fromAssetAddress] += transaction.swapOutGasFee;
            s.depositsByAsset[v.fromAssetAddress][msg.sender] += transaction.swapOutGasFee;
        }

        v.toAssetAddress.withdraw(s.weth, v.toAddress, amountOut);

        emit SwapOut(
            msg.sender,
            v.toAddress,
            v.fromAssetAddress,
            v.toAssetAddress,
            v.amountIn,
            amountOut,
            transferKey,
            transaction
        );
    }

    event Withdraw(address indexed sender, address indexed assetAddress, uint256 amount);

    function withdraw(address assetAddress) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 deposit = s.depositsByAsset[assetAddress][msg.sender];

        if (deposit == 0) {
            revert DepositIsZero();
        }

        s.deposits[assetAddress] -= deposit;
        s.depositsByAsset[assetAddress][msg.sender] = 0;

        assetAddress.transfer(payable(msg.sender), deposit);

        emit Withdraw(msg.sender, assetAddress, deposit);
    }

    function simulateSwap(SwapArgs memory swapArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 amountIn = swapArgs.amountIns.sum();
        address fromAssetAddress = swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapArgs.addresses.toAddress(40);

        fromAssetAddress.deposit(s.weth, amountIn);

        if (fromAssetAddress == toAssetAddress) {
            amountOut = amountIn;
        } else {
            amountOut = LibRouter.swap(swapArgs);
        }

        s.deposits[toAssetAddress] += amountOut;
        s.depositsByAsset[toAssetAddress][msg.sender] += amountOut;

        emit Swap(msg.sender, msg.sender, fromAssetAddress, toAssetAddress, amountIn, amountOut);
    }

    function simulateTransfer(
        SwapArgs calldata swapArgs,
        bool shouldTransfer,
        bool useTransferFrom
    ) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 amountIn = swapArgs.amountIns.sum();
        address fromAssetAddress = swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapArgs.addresses.toAddress(40);

        fromAssetAddress.deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapArgs);

        if (shouldTransfer) {
            if (useTransferFrom) {
                s.deposits[toAssetAddress] += amountOut;
                s.depositsByAsset[toAssetAddress][msg.sender] += amountOut;
                toAssetAddress.transferFrom(address(this), address(this), amountOut);
            } else {
                toAssetAddress.withdraw(s.weth, msg.sender, amountOut);
            }
        }

        emit Swap(msg.sender, msg.sender, fromAssetAddress, toAssetAddress, amountIn, amountOut);
    }

    event Paused(address sender);

    function pause() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.paused = true;
        emit Paused(msg.sender);
    }

    event Unpaused(address sender);

    function unpause() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.paused = false;
        emit Paused(msg.sender);
    }

    function enforceIsNotPaused() internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.paused) {
            revert ContractIsPaused();
        }
    }

    function enforcePreGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.guarded) {
            revert ReentrantCall();
        }

        s.guarded = true;
    }

    function enforcePostGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.guarded = false;
    }

    function enforceDeadline(uint256 deadline) internal view {
        if (deadline < block.timestamp) {
            revert ExpiredTransaction();
        }
    }
}