pragma solidity ^0.8.7;

import "./Dex/IAggregationRouterV4.sol";

struct FromChainData {
    address _fromToken;
    address _toToken;
    uint256 _amount;
    bytes _extraParams;
    uint16 _commLayerID;
    DexData _dex;
}

struct ToChainData {
    address _fromToken;
    address _toToken;
    address _destination;
    address _receiver;
    DexData _dex;
}

struct DexData {
    IAggregationExecutor _executor;
    SwapDescription _desc;
    bytes _data;
}

struct SwapData {
    FromChainData fromChain;
    ToChainData toChain;
}