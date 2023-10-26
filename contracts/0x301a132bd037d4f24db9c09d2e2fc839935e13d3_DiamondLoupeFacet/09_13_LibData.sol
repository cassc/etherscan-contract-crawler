// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/Structs.sol";

library LibData {
    bytes32 internal constant BRIDGE_NAMESPACE = keccak256("diamond.standard.data.bridge");
    bytes32 internal constant STARGATE_NAMESPACE = keccak256("diamond.standard.data.stargate");
    bytes32 internal constant CONNEXT_NAMESPACE = keccak256("diamond.standard.data.connext");
    bytes32 internal constant HOP_NAMESPACE = keccak256("com.plexus.facets.hop");

    event Bridge(address user, uint64 chainId, address srcToken, uint256 fromAmount, bytes plexusData, string bridge);

    event Swap(address user, InputToken[] input, OutputToken[] output, uint256[] returnAmount, bytes plexusData);

    event Relayswap(address receiver, OutputToken[] output, uint256[] returnAmount, bytes plexusData);

    struct BridgeDesc {
        mapping(bytes32 => BridgeInfo) transferInfo;
        mapping(bytes32 => bool) transfers;
    }

    struct StargateData {
        mapping(address => uint16) poolId;
        mapping(address => mapping(uint256 => uint16)) dstPoolId;
        mapping(uint256 => uint16) layerZeroId;
    }

    struct HopBridgeData {
        mapping(address => address) bridge;
        mapping(address => address) relayer;
        mapping(address => bool) allowedRelayer;
        mapping(address => bool) allowedBridge;
    }

    struct ConnextBridgeData {
        mapping(uint64 => uint64) domainId;
    }

    function bridgeStorage() internal pure returns (BridgeDesc storage ds) {
        bytes32 position = BRIDGE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    function stargateStorage() internal pure returns (StargateData storage s) {
        bytes32 position = STARGATE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function hopStorage() internal pure returns (HopBridgeData storage s) {
        bytes32 position = HOP_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function connextStorage() internal pure returns (ConnextBridgeData storage s) {
        bytes32 position = CONNEXT_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}