// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

enum BridgeType {
    Wormhole,
    Stargate
}

enum DataTransferType {
    Wormhole,
    LayerZero
}

struct CurveSettings {
    address mainRegistry;
    address cryptoRegistry;
    address cryptoFactory;
}

struct Amm {
    uint8 protocolId;
    bytes4 selector;
    address addr;
}

struct WormholeBridgeSettings {
    address bridgeAddress;
}

struct StargateSettings {
    address routerAddress;
}

struct WormholeSettings {
    address bridgeAddress;
    uint8 consistencyLevel;
}

struct LayerZeroSettings {
    address routerAddress;
}

struct AppStorage {
    address weth;
    uint16 networkId;
    mapping(uint16 => bytes32) magpieAggregatorAddresses;
    mapping(address => uint256) deposits;
    mapping(address => mapping(address => uint256)) depositsByUser;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => bool))) usedTransferKeys;
    // Pausable
    bool paused;
    // Reentrancy Guard
    bool guarded;
    // Amm
    mapping(uint16 => Amm) amms;
    // Curve Amm
    CurveSettings curveSettings;
    // Data Transfer
    uint64 coreSequence;
    mapping(uint16 => mapping(uint16 => mapping(bytes32 => mapping(uint64 => bytes)))) payloads;
    // Bridge
    uint64 tokenSequence;
    // Stargate Bridge
    StargateSettings stargateSettings;
    mapping(uint16 => bytes32) magpieStargateBridgeAddresses;
    // Wormhole Bridge
    WormholeBridgeSettings wormholeBridgeSettings;
    // Wormhole Data Transfer
    WormholeSettings wormholeSettings;
    mapping(uint16 => uint16) wormholeNetworkIds;
    mapping(uint64 => uint64) wormholeCoreSequences;
    // LayerZero Data Transfer
    LayerZeroSettings layerZeroSettings;
    mapping(uint16 => uint16) layerZeroChainIds;
    mapping(uint16 => uint16) layerZeroNetworkIds;
    mapping(uint64 => uint64) wormholeTokenSequences;
}

library LibMagpieAggregator {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}