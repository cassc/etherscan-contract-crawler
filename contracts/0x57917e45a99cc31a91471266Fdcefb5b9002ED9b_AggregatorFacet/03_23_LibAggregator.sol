// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";
import {LibRouter, SwapArgs} from "../router/LibRouter.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {BridgeArgs, BridgeInArgs, BridgeOutArgs} from "../bridge/LibCommon.sol";
import {LibTransaction, Transaction, TransactionValidation} from "../bridge/LibTransaction.sol";
import {DataTransferInArgs, DataTransferInProtocol, DataTransferOutArgs, DataTransferType} from "../data-transfer/LibCommon.sol";

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

error AggregatorDepositIsZero();
error AggregatorInvalidAmountIn();
error AggregatorInvalidAmountOutMin();
error AggregatorInvalidFromAssetAddress();
error AggregatorInvalidMagpieAggregatorAddress();
error AggregatorInvalidToAddress();
error AggregatorInvalidToAssetAddress();
error AggregatorInvalidTransferKey();
error AggregatorBridgeInCallFailed();
error AggregatorBridgeOutCallFailed();
error AggregatorDataTransferInCallFailed();
error AggregatorDataTransferOutCallFailed();

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

        amountOut = LibRouter.swap(swapArgs, !toAssetAddress.isNative());

        if (toAssetAddress.isNative()) {
            toAssetAddress.withdraw(s.weth, toAddress, amountOut);
        }

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
            revert AggregatorInvalidToAddress();
        }

        uint256 amountIn = swapInArgs.swapArgs.amountIns.sum();
        address fromAssetAddress = swapInArgs.swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapInArgs.swapArgs.addresses.toAddress(40);

        fromAssetAddress.deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapInArgs.swapArgs, false);

        s.swapSequence += 1;
        TransferKey memory transferKey = TransferKey({
            networkId: s.networkId,
            senderAddress: bytes32(uint256(uint160(address(this)))),
            swapSequence: s.swapSequence
        });

        bridgeIn(
            BridgeInArgs({
                recipientNetworkId: swapInArgs.dataTransferInProtocol.networkId,
                bridgeArgs: swapInArgs.bridgeArgs,
                amount: amountOut,
                toAssetAddress: toAssetAddress,
                transferKey: transferKey
            })
        );

        Transaction memory transaction = Transaction({
            dataTransferType: swapInArgs.dataTransferInProtocol.dataTransferType,
            bridgeType: swapInArgs.bridgeArgs.bridgeType,
            recipientNetworkId: swapInArgs.dataTransferInProtocol.networkId,
            fromAssetAddress: swapInArgs.transactionValidation.fromAssetAddress,
            toAssetAddress: swapInArgs.transactionValidation.toAssetAddress,
            toAddress: swapInArgs.transactionValidation.toAddress,
            recipientAggregatorAddress: s.magpieAggregatorAddresses[swapInArgs.dataTransferInProtocol.networkId],
            amountOutMin: swapInArgs.transactionValidation.amountOutMin,
            swapOutGasFee: swapInArgs.transactionValidation.swapOutGasFee
        });

        dataTransferIn(
            DataTransferInArgs({
                protocol: swapInArgs.dataTransferInProtocol,
                transferKey: transferKey,
                payload: LibTransaction.encode(transaction)
            })
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

        (TransferKey memory transferKey, bytes memory payload) = dataTransferOut(swapOutArgs.dataTransferOutArgs);

        if (s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence]) {
            revert AggregatorInvalidTransferKey();
        }

        s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence] = true;

        Transaction memory transaction = LibTransaction.decode(payload);

        SwapOutVariables memory v = SwapOutVariables({
            bridgeAmount: bridgeOut(
                BridgeOutArgs({bridgeArgs: swapOutArgs.bridgeArgs, transaction: transaction, transferKey: transferKey})
            ),
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
            revert AggregatorInvalidFromAssetAddress();
        }

        if (msg.sender != v.transactionToAddress) {
            if (address(uint160(uint256(transaction.toAssetAddress))) != v.toAssetAddress) {
                revert AggregatorInvalidToAssetAddress();
            }
        }

        if (v.transactionToAddress != v.toAddress || v.transactionToAddress == address(this)) {
            revert AggregatorInvalidToAddress();
        }

        if (address(uint160(uint256(transaction.recipientAggregatorAddress))) != address(this)) {
            revert AggregatorInvalidMagpieAggregatorAddress();
        }

        if (swapOutArgs.swapArgs.amountOutMin < transaction.amountOutMin) {
            revert AggregatorInvalidAmountOutMin();
        }

        if (swapOutArgs.swapArgs.amountIns[0] <= transaction.swapOutGasFee) {
            revert AggregatorInvalidAmountIn();
        }

        if (v.amountIn > v.bridgeAmount) {
            revert AggregatorInvalidAmountIn();
        }

        swapOutArgs.swapArgs.amountIns[0] =
            swapOutArgs.swapArgs.amountIns[0] +
            (v.bridgeAmount > v.amountIn ? v.bridgeAmount - v.amountIn : 0) -
            transaction.swapOutGasFee;
        v.amountIn = swapOutArgs.swapArgs.amountIns.sum();

        if (transaction.swapOutGasFee > 0) {
            s.deposits[v.fromAssetAddress] += transaction.swapOutGasFee;
            s.depositsByUser[v.fromAssetAddress][msg.sender] += transaction.swapOutGasFee;
        }

        amountOut = LibRouter.swap(swapOutArgs.swapArgs, !v.toAssetAddress.isNative());

        if (v.toAssetAddress.isNative()) {
            v.toAssetAddress.withdraw(s.weth, v.toAddress, amountOut);
        }

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

        uint256 deposit = s.depositsByUser[assetAddress][msg.sender];

        if (deposit == 0) {
            revert AggregatorDepositIsZero();
        }

        s.deposits[assetAddress] -= deposit;
        s.depositsByUser[assetAddress][msg.sender] = 0;

        assetAddress.transfer(msg.sender, deposit);

        emit Withdraw(msg.sender, assetAddress, deposit);
    }

    function getDeposit(address assetAddress) internal view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.deposits[assetAddress];
    }

    function getPayload(
        DataTransferType dataTransferType,
        uint16 senderNetworkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) internal view returns (bytes memory) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        return s.payloads[uint16(dataTransferType)][senderNetworkId][senderAddress][swapSequence];
    }

    function getDepositByUser(address assetAddress, address senderAddress) internal view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.depositsByUser[assetAddress][senderAddress];
    }

    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) internal view returns (bool) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        return s.usedTransferKeys[networkId][senderAddress][swapSequence];
    }

    function bridgeIn(BridgeInArgs memory bridgeInArgs) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"2312b1a3";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory bridgeInCall = abi.encodeWithSelector(selector, bridgeInArgs);
        (bool success, ) = address(facet).delegatecall(bridgeInCall);
        if (!success) {
            revert AggregatorBridgeInCallFailed();
        }
    }

    function bridgeOut(BridgeOutArgs memory bridgeOutArgs) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"c6687b9d";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory bridgeOutCall = abi.encodeWithSelector(selector, bridgeOutArgs);
        (bool success, bytes memory data) = address(facet).delegatecall(bridgeOutCall);
        if (!success) {
            revert AggregatorBridgeOutCallFailed();
        }

        return abi.decode(data, (uint256));
    }

    function dataTransferIn(DataTransferInArgs memory dataTransferInArgs) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"7f2bf445";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory dataTransferInCall = abi.encodeWithSelector(selector, dataTransferInArgs);
        (bool success, ) = address(facet).delegatecall(dataTransferInCall);
        if (!success) {
            revert AggregatorDataTransferInCallFailed();
        }
    }

    function dataTransferOut(DataTransferOutArgs memory dataTransferOutArgs)
        internal
        returns (TransferKey memory, bytes memory)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"83d5b76e";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory dataTransferOutCall = abi.encodeWithSelector(selector, dataTransferOutArgs);
        (bool success, bytes memory data) = address(facet).delegatecall(dataTransferOutCall);
        if (!success) {
            revert AggregatorDataTransferOutCallFailed();
        }

        return abi.decode(data, (TransferKey, bytes));
    }
}