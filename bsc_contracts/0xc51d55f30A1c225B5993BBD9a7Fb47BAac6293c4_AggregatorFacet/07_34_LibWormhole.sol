// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, DataTransferType, LibMagpieAggregator, WormholeBridgeSettings} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {IWormhole} from "../interfaces/wormhole/IWormhole.sol";
import {IWormholeCore} from "../interfaces/wormhole/IWormholeCore.sol";
import {Transaction, TransactionValidation} from "./LibTransaction.sol";
import {BridgeArgs} from "./LibBridge.sol";

struct WormholeBridgeInData {
    uint16 recipientBridgeChainId;
}

error WormholeInvalidTokenSequence();

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
        uint16 recipientNetworkId,
        uint64 tokenSequence,
        BridgeArgs memory bridgeArgs,
        uint256 amount,
        address toAssetAddress
    ) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        // Dust management
        uint8 toAssetDecimals = toAssetAddress.getDecimals();
        if (toAssetDecimals > 8) {
            amount = normalize(toAssetDecimals, 8, amount);
            amount = denormalize(8, toAssetDecimals, amount);
        }

        bytes memory payload = new bytes(8);

        assembly {
            mstore(add(payload, 32), shl(192, tokenSequence))
        }

        toAssetAddress.approve(s.wormholeBridgeSettings.bridgeAddress, amount);
        uint64 wormholeTokenSequence = IWormhole(s.wormholeBridgeSettings.bridgeAddress).transferTokensWithPayload(
            toAssetAddress,
            amount,
            getRecipientBridgeChainId(bridgeArgs.payload),
            s.magpieAggregatorAddresses[recipientNetworkId],
            uint32(block.timestamp % 2**32),
            payload
        );

        s.wormholeTokenSequences[tokenSequence] = wormholeTokenSequence;
    }

    function bridgeOut(bytes memory bridgeOutPayload, Transaction memory transaction)
        internal
        returns (uint256 amount)
    {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        // We dont have to verify because completeTransfer will do it
        IWormholeCore.VM memory vm = IWormholeCore(s.wormholeSettings.bridgeAddress).parseVM(bridgeOutPayload);

        bytes memory vmPayload = vm.payload;
        uint64 tokenSequence;

        assembly {
            amount := mload(add(vmPayload, 33))
            tokenSequence := shr(192, mload(add(vmPayload, 165)))
        }

        if (transaction.tokenSequence != tokenSequence) {
            revert WormholeInvalidTokenSequence();
        }

        uint8 fromAssetDecimals = address(uint160(uint256(transaction.fromAssetAddress))).getDecimals();
        if (fromAssetDecimals > 8) {
            amount = denormalize(8, fromAssetDecimals, amount);
        }

        IWormhole(s.wormholeBridgeSettings.bridgeAddress).completeTransfer(bridgeOutPayload);
    }

    function getTokenSequence(uint64 tokenSequence) internal view returns (uint64) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.wormholeTokenSequences[tokenSequence];
    }
}