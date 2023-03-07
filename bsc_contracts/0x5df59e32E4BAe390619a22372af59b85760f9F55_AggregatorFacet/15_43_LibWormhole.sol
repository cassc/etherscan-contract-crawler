// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator, WormholeBridgeSettings} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {IWormhole} from "../interfaces/wormhole/IWormhole.sol";
import {IWormholeCore} from "../interfaces/wormhole/IWormholeCore.sol";
import {DataTransferType, LibDataTransfer} from "../data-transfer/LibDataTransfer.sol";
import {Transaction, TransactionValidation} from "./LibTransaction.sol";
import {BridgeArgs} from "./LibBridge.sol";
import "../libraries/LibError.sol";

struct WormholeBridgeInData {
    uint16 recipientBridgeChainId;
}

library LibWormhole {
    using LibAsset for address;

    event UpdateWormholeBridgeSettings(address indexed sender, WormholeBridgeSettings wormholeBridgeSettings);

    function updateSettings(WormholeBridgeSettings memory wormholeBridgeSettings) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.wormholeBridgeSettings = wormholeBridgeSettings;

        emit UpdateWormholeBridgeSettings(msg.sender, wormholeBridgeSettings);
    }

    function normalize(
        uint8 fromDecimals,
        uint8 toDecimals,
        uint256 amount
    ) private pure returns (uint256) {
        amount /= 10**(fromDecimals - toDecimals);
        return amount;
    }

    function denormalize(
        uint8 fromDecimals,
        uint8 toDecimals,
        uint256 amount
    ) private pure returns (uint256) {
        amount *= 10**(toDecimals - fromDecimals);
        return amount;
    }

    function getRecipientBridgeChainId(bytes memory bridgeInPayload)
        private
        pure
        returns (uint16 recipientBridgeChainId)
    {
        assembly {
            recipientBridgeChainId := shr(240, mload(add(bridgeInPayload, 32)))
        }
    }

    function bridgeIn(
        TransactionValidation memory transactionValidation,
        BridgeArgs memory bridgeArgs,
        uint256 amount,
        address toAssetAddress
    ) internal returns (uint64 tokenSequence) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        // Dust management
        uint8 toAssetDecimals = toAssetAddress.getDecimals();
        if (toAssetDecimals > 8) {
            amount = normalize(toAssetDecimals, 8, amount);
            amount = denormalize(8, toAssetDecimals, amount);
        }

        toAssetAddress.approve(s.wormholeBridgeSettings.bridgeAddress, amount);
        tokenSequence = IWormhole(s.wormholeBridgeSettings.bridgeAddress).transferTokens(
            toAssetAddress,
            amount,
            getRecipientBridgeChainId(bridgeArgs.payload),
            transactionValidation.recipientAggregatorAddress,
            0,
            uint32(block.timestamp % 2**32)
        );
    }

    function bridgeOut(bytes memory bridgeOutPayload, Transaction memory transaction)
        internal
        returns (uint256 amount)
    {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        (IWormholeCore.VM memory vm, bool valid, string memory reason) = IWormholeCore(
            s.wormholeBridgeSettings.bridgeAddress
        ).parseAndVerifyVM(bridgeOutPayload);
        require(valid, reason);

        if (transaction.tokenSequence != vm.sequence) {
            revert InvalidTokenSequence();
        }

        bytes memory vmPayload = vm.payload;

        assembly {
            amount := mload(add(vmPayload, 33))
        }

        uint8 fromAssetDecimals = address(uint160(uint256(transaction.fromAssetAddress))).getDecimals();
        if (fromAssetDecimals > 8) {
            amount = denormalize(8, fromAssetDecimals, amount);
        }

        IWormhole(s.wormholeBridgeSettings.bridgeAddress).completeTransfer(bridgeOutPayload);
    }
}