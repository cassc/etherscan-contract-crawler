// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

library Bytes32Conversion {
    function toAddress(bytes32 b32) internal pure returns (address) {
        return address(uint160(bytes20(b32)));
    }
}

interface IResonate {

        // Uses 3 storage slots
    struct PoolConfig {
        address asset; // 20
        address vault; // 20 
        address adapter; // 20
        uint32  lockupPeriod; // 4
        uint128  rate; // 16
        uint128  addInterestRate; //Amount additional (10% on top of the 30%) - If not a bond then just zero // 16
        uint256 packetSize; // 32
    }

    // Uses 1 storage slot
    struct PoolQueue {
        uint64 providerHead;
        uint64 providerTail;
        uint64 consumerHead;
        uint64 consumerTail;
    }

    // Uses 3 storage slot
    struct Order {
        uint256 packetsRemaining;
        uint256 depositedShares;
        bytes32 owner;
    }

    struct ParamPacker {
        Order consumerOrder;
        Order producerOrder;
        bool isProducerNew;
        bool isCrossAsset;
        uint quantityPackets; 
        uint currentExchangeRate;
        PoolConfig pool;
        address adapter;
        bytes32 poolId;
    }

    /// Uses 4 storage slots
    /// Stores information on activated positions
    struct Active {
        // The ID of the associated Principal FNFT
        // Interest FNFT will be this +1
        uint256 principalId; 
        // Set at the time you last claim interest
        // Current state of interest - current shares per asset
        uint256 sharesPerPacket; 
        // Zero measurement point at pool creation
        // Left as zero if Type0
        uint256 startingSharesPerPacket; 
        bytes32 poolId;
    }

    ///
    /// Events
    ///

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event PoolCreated(bytes32 indexed poolId, address indexed asset, address indexed vault, address payoutAsset, uint128 rate, uint128 addInterestRate, uint32 lockupPeriod, uint256 packetSize, bool isFixedTerm, string poolName, address creator);

    event EnqueueProvider(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);
    event EnqueueConsumer(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);

    event DequeueProvider(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);
    event DequeueConsumer(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);

    event OracleRegistered(address indexed vaultAsset, address indexed paymentAsset, address indexed oracleDispatch);

    event VaultAdapterRegistered(address indexed underlyingVault, address indexed vaultAdapter, address indexed vaultAsset);

    event CapitalActivated(bytes32 indexed poolId, uint numPackets, uint indexed principalFNFT);
    
    event OrderWithdrawal(bytes32 indexed poolId, uint amountPackets, bool fullyWithdrawn, address owner);

    event FNFTCreation(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);
    event FNFTRedeemed(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);

    event FeeCollection(bytes32 indexed poolId, uint amountTokens);

    event InterestClaimed(bytes32 indexed poolId, uint indexed fnftId, address indexed claimer, uint amount);
    event BatchInterestClaimed(bytes32 indexed poolId, uint[] fnftIds, address indexed claimer, uint amountInterest);
    
    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);
    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    function residuals(uint fnftId) external view returns (uint residual);
    function RESONATE_HELPER() external view returns (address resonateHelper);

    function queueMarkers(bytes32 poolId) external view returns (uint64 a, uint64 b, uint64 c, uint64 d);
    function providerQueue(bytes32 poolId, uint256 providerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function consumerQueue(bytes32 poolId, uint256 consumerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function activated(uint fnftId) external view returns (uint principalId, uint sharesPerPacket, uint startingSharesPerPacket, bytes32 poolId);
    function pools(bytes32 poolId) external view returns (address asset, address vault, address adapter, uint32 lockupPeriod, uint128 rate, uint128 addInterestRate, uint256 packetSize);
    function vaultAdapters(address vault) external view returns (address vaultAdapter);
    function fnftIdToIndex(uint fnftId) external view returns (uint index);
    function REGISTRY_ADDRESS() external view returns (address registry);

    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable owner,
        uint quantity
    ) external;

    function claimInterest(uint fnftId, address recipient) external;
}