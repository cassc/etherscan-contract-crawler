// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract RegistryStorage {

    struct BridgeTokenMetadata {
        string name;
        string imageUrl;
        address tokenAddress;
    }
    
    // ticker => BridgeTokenMetadata
    mapping(string => BridgeTokenMetadata) public bridgeTokenMetadata;


    struct FeeConfig {
        uint8 feeType; //0: parent chain; 1: % of tokens
        uint256 feeInBips;
    }

    struct TokenBridge {
        uint8 bridgeType;
        string tokenTicker;
        uint256 startBlock;
        uint256 epochLength;
        FeeConfig fee;
        // uint256 totalFeeCollected;
        // uint256 totalActiveLiquidity;
        uint256 noOfDepositors;
        bool isActive;
    }
    // tokenTicker => TokenBridge
    mapping(string => TokenBridge) public tokenBridge;

    // array of all the token tickers
    string[] public tokenBridges;

    bool public isBridgeActive;

    uint256[100] private __gap;

}