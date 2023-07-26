pragma solidity 0.8.17;

interface IBridge {
    struct BridgeData {
        address srcToken;
        uint256 amount;
        uint64 dstChainId;
        address recipient;
        bytes plexusData;
    }
}