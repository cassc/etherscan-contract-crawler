// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {TransferKey} from "../data-transfer/LibDataTransfer.sol";
import {AppStorage, LibMagpieAggregator, StargateSettings} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {IStargateRouter} from "../interfaces/stargate/IStargateRouter.sol";
import {IStargatePool} from "../interfaces/stargate/IStargatePool.sol";
import {IStargateFactory} from "../interfaces/stargate/IStargateFactory.sol";
import {IStargateFeeLibrary} from "../interfaces/stargate/IStargateFeeLibrary.sol";
import {Transaction, TransactionValidation} from "./LibTransaction.sol";
import {BridgeArgs, BridgeType} from "./LibBridge.sol";
import "../libraries/LibError.sol";

struct StargateBridgeInData {
    uint16 layerZeroRecipientChainId;
    uint256 sourcePoolId;
    uint256 destPoolId;
    uint256 fee;
}

struct StargateBridgeOutData {
    bytes srcAddress;
    uint256 nonce;
    uint16 srcChainId;
}

struct ExecuteBridgeInArgs {
    uint16 networkId;
    uint64 tokenSequence;
    address routerAddress;
    uint256 amount;
    bytes recipientAggregatorAddress;
    StargateBridgeInData bridgeInData;
    IStargateRouter.lzTxObj lzTxObj;
}

library LibStargate {
    using LibAsset for address;
    using LibBytes for bytes;

    event UpdateStargateSettings(address indexed sender, StargateSettings stargateSettings);

    function updateSettings(StargateSettings memory stargateSettings) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.stargateSettings = stargateSettings;

        emit UpdateStargateSettings(msg.sender, stargateSettings);
    }

    function createPayload(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 tokenSequence
    ) internal pure returns (bytes memory payload) {
        payload = new bytes(42);
        assembly {
            mstore(add(payload, 32), shl(240, networkId))
            mstore(add(payload, 34), senderAddress)
            mstore(add(payload, 66), shl(192, tokenSequence))
        }
    }

    function decodePayload(bytes memory payload)
        internal
        pure
        returns (
            uint16 networkId,
            bytes32 senderAddress,
            uint64 tokenSequence
        )
    {
        assembly {
            networkId := shr(240, mload(add(payload, 32)))
            senderAddress := mload(add(payload, 34))
            tokenSequence := shr(192, mload(add(payload, 66)))
        }
    }

    function decodeBridgeInPayload(bytes memory bridgeInPayload)
        internal
        pure
        returns (StargateBridgeInData memory bridgeInData)
    {
        assembly {
            mstore(bridgeInData, shr(240, mload(add(bridgeInPayload, 32))))
            mstore(add(bridgeInData, 32), mload(add(bridgeInPayload, 34)))
            mstore(add(bridgeInData, 64), mload(add(bridgeInPayload, 66)))
            mstore(add(bridgeInData, 96), mload(add(bridgeInPayload, 98)))
        }
    }

    function decodeBridgeOutPayload(bytes memory bridgeOutPayload)
        internal
        pure
        returns (StargateBridgeOutData memory bridgeOutData)
    {
        uint256 nonce;
        uint16 srcChainId;

        assembly {
            nonce := mload(add(bridgeOutPayload, 72))
            srcChainId := shr(240, mload(add(bridgeOutPayload, 104)))
        }

        bridgeOutData.srcAddress = bridgeOutPayload.slice(0, 40);
        bridgeOutData.nonce = nonce;
        bridgeOutData.srcChainId = srcChainId;
    }

    function getMinAmountLD(uint256 amount, StargateBridgeInData memory bridgeInData) private view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        address stargateFactoryAddress = IStargateRouter(s.stargateSettings.routerAddress).factory();
        address poolAddress = IStargateFactory(stargateFactoryAddress).getPool(bridgeInData.sourcePoolId);
        address feeLibraryAddress = IStargatePool(poolAddress).feeLibrary();
        uint256 convertRate = IStargatePool(poolAddress).convertRate();
        IStargatePool.SwapObj memory swapObj = IStargateFeeLibrary(feeLibraryAddress).getFees(
            bridgeInData.sourcePoolId,
            bridgeInData.destPoolId,
            bridgeInData.layerZeroRecipientChainId,
            address(this),
            amount / convertRate
        );
        swapObj.amount =
            (amount / convertRate - (swapObj.eqFee + swapObj.protocolFee + swapObj.lpFee) + swapObj.eqReward) *
            convertRate;
        return swapObj.amount;
    }

    function bridgeIn(
        TransactionValidation memory transactionValidation,
        BridgeArgs memory bridgeArgs,
        uint256 amount,
        address toAssetAddress
    ) internal returns (uint64 tokenSequence) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        toAssetAddress.approve(s.stargateSettings.routerAddress, amount);

        s.tokenSequence += 1;
        tokenSequence = s.tokenSequence;

        executeBridgeIn(
            ExecuteBridgeInArgs({
                recipientAggregatorAddress: abi.encodePacked(
                    address(uint160(uint256(transactionValidation.recipientAggregatorAddress)))
                ),
                bridgeInData: decodeBridgeInPayload(bridgeArgs.payload),
                lzTxObj: IStargateRouter.lzTxObj(0, 0, abi.encodePacked(msg.sender)),
                tokenSequence: tokenSequence,
                amount: amount,
                networkId: s.networkId,
                routerAddress: s.stargateSettings.routerAddress
            })
        );
    }

    function executeBridgeIn(ExecuteBridgeInArgs memory executeBridgeInArgs) internal {
        IStargateRouter(executeBridgeInArgs.routerAddress).swap{value: executeBridgeInArgs.bridgeInData.fee}(
            executeBridgeInArgs.bridgeInData.layerZeroRecipientChainId,
            executeBridgeInArgs.bridgeInData.sourcePoolId,
            executeBridgeInArgs.bridgeInData.destPoolId,
            payable(msg.sender),
            executeBridgeInArgs.amount,
            getMinAmountLD(executeBridgeInArgs.amount, executeBridgeInArgs.bridgeInData),
            executeBridgeInArgs.lzTxObj,
            executeBridgeInArgs.recipientAggregatorAddress,
            createPayload(
                executeBridgeInArgs.networkId,
                bytes32(uint256(uint160(address(this)))),
                executeBridgeInArgs.tokenSequence
            )
        );
    }

    function bridgeOut(
        bytes memory bridgeOutPayload,
        Transaction memory transaction,
        TransferKey memory transferKey
    ) internal returns (uint256 amount) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        StargateBridgeOutData memory bridgeOutData = decodeBridgeOutPayload(bridgeOutPayload);

        address fromAssetAddress = address(uint160(uint256(transaction.fromAssetAddress)));

        // If somebody called it manually we just skip it
        if (
            IStargateRouter(s.stargateSettings.routerAddress)
                .cachedSwapLookup(bridgeOutData.srcChainId, abi.encode(bridgeOutData.srcAddress), bridgeOutData.nonce)
                .to != address(0x0)
        ) {
            IStargateRouter(s.stargateSettings.routerAddress).clearCachedSwap(
                bridgeOutData.srcChainId,
                abi.encode(bridgeOutData.srcAddress),
                bridgeOutData.nonce
            );
        }

        amount = s.stargateDeposits[transferKey.networkId][transferKey.senderAddress][transaction.tokenSequence][
            fromAssetAddress
        ];
        s.stargateDeposits[transferKey.networkId][transferKey.senderAddress][transaction.tokenSequence][
            fromAssetAddress
        ] = 0;
        s.deposits[fromAssetAddress] -= amount;
    }

    function sgReceive(
        address assetAddress,
        uint256 amount,
        bytes memory payload
    ) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        (uint16 networkId, bytes32 senderAddress, uint64 tokenSequence) = decodePayload(payload);
        s.stargateDeposits[networkId][senderAddress][tokenSequence][assetAddress] += amount;
        s.deposits[assetAddress] += amount;
    }

    function enforce() internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        if (msg.sender != s.stargateSettings.routerAddress) {
            revert InvalidSender();
        }
    }
}