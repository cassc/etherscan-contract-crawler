// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { GasFunctionType } from './ITransport.sol';

library TransportStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Transport');

    // solhint-disable-next-line ordering
    struct Layout {
        Registry registry;
        ILayerZeroEndpoint lzEndpoint;
        mapping(address => bool) isVault;
        mapping(uint16 => bytes) trustedRemoteLookup;
        address stargateRouter;
        mapping(address => uint) stargateAssetToSrcPoolId;
        // (chainId => (asset => poolId))
        mapping(uint16 => mapping(address => uint)) stargateAssetToDstPoolId;
        uint bridgeApprovalCancellationTime;
        mapping(GasFunctionType => uint) DEPRECATED_gasUsage;
        mapping(uint16 => uint) returnMessageCosts;
        // ChainId => (GasFunctionType => gasUsage)
        // The amount of gas needed for delivery on the destination can change
        // Based on the max number of assets that can be enabled in a vault on that chain
        mapping(uint16 => mapping(GasFunctionType => uint)) gasUsage;
        uint vaultCreationFee;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}