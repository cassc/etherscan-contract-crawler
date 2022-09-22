// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract BridgeStorage {

    struct LiquidityPosition {
        uint256 depositedAmount;
        uint256 blockNo;
        uint256 claimedTillEpochIndex;
        uint256 epochStartIndex;
        uint256 epochStartBlock;
        uint256 boosterEndEpochIndex;
        uint256 startTimestamp;
    }

    // tokenTicker => userAddress => index => LiquidityPosition
    mapping(string => mapping(address => mapping(uint256 => LiquidityPosition))) public liquidityPosition;
    // tokenTicker => userAddress => index => epochIndex => hasBooster
    mapping(string => mapping(address => mapping(uint256 => mapping(uint256 => bool)))) public hasBooster;
    // tokenTicker => userAddress => index
    mapping(string => mapping(address => uint256)) public currentIndex;
    // tokenTicker => totalLiquidity
    mapping(string => uint256) public totalLiquidity;
    // tokenTicker => totalLiquidity
    mapping(string => uint256) public totalLpLiquidity;
    // tokenTicker => epochIndex => totalBoostedLiquidity
    mapping(string => mapping(uint256 => uint256)) public totalBoostedLiquidity;

    // to create a mapping for verifying the cross chain transfer
    // struct TransferMapping {
    //     address userAddress;
    //     uint256 noOfTokens;
    // }
    // tokenTicker => index => TransferMapping
    // mapping(string => mapping(uint256 => TransferMapping)) public transferMapping;
    // tokenTicker => userAddress => srcChain => destChain => index => noOfTokens
    // mapping(string => mapping(address => mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256))))) public transferMapping;
    mapping(bytes32 => uint256) public transferMapping;

    // unique for each transfer mapping
    // tokenTicker => userAddress => srcChain => destChain => index
    // mapping(string => mapping(address => mapping(uint8 => mapping(uint8 => uint256)))) public currentTransferIndex;
    mapping(bytes32 => uint256) public currentTransferIndex;

    struct Epoch {
        uint256 startBlock;
        uint256 epochLength;
        uint256 totalFeesCollected;
        uint256 totalActiveLiquidity;
        uint256 noOfDepositors;
    }
    // tokenTicker => Epoch[]
    mapping(string => Epoch[]) public epochs;

    // to recalculate the fees and totalLiquidity once epoch ends
    // (updated on the first call after epoch ends)
    // ticker => nextEpochBlock
    mapping(string => uint256) public nextEpochBlock;

    // mapping(string => uint256) public adminClaimedTillEpoch;

    // minimum fee can be 0.1% (= 1 bip), so 100% = 1000bips (=maxBips)
    uint256 public maxBips;

    uint256 public crossChainGas;

    struct BoosterConfig {
        // uint8 tokenType;
        address tokenAddress;
        uint256 price;
        string imageUrl;
        address adminAccount;
    }
    BoosterConfig public boosterConfig;

    uint8 public chainId;

    uint256[100] private __gap;

}