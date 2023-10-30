/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

// SPDX-License-Identifier: BUSL-1.1
// File: lib/ipor-protocol/contracts/interfaces/IIporContractCommonGov.sol


pragma solidity 0.8.20;

/// @title Interface for interaction with standalone IPOR smart contract by DAO government with common methods.
interface IIporContractCommonGov {
    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from AssetManagement.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AssetManagement.
    function unpause() external;

    /// @notice Checks if given account is a pause guardian.
    /// @param account The address of the account to be checked.
    /// @return true if account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param guardians The list of addresses of the pause guardians to be added.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param guardians The list of addresses of the pause guardians to be removed.
    function removePauseGuardians(address[] calldata guardians) external;
}

// File: lib/ipor-protocol/contracts/oracles/libraries/IporRiskManagementOracleStorageTypes.sol


pragma solidity 0.8.20;

/// @notice types used in IporRiskManagementOracle's storage
library IporRiskManagementOracleStorageTypes {
    struct RiskIndicatorsStorage {
        /// @notice max notional for pay fixed leg, value is without decimals, is a multiplication of 10_000, example: 1 = 10k
        uint64 maxNotionalPayFixed;
        /// @notice max notional for receive fixed leg, value is without decimals, is a multiplication of 10_000, example: 1 = 10k
        uint64 maxNotionalReceiveFixed;
        /// @notice collateral ratio for pay fixed leg, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint16 maxCollateralRatioPayFixed;
        /// @notice collateral ratio for receive fixed leg, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint16 maxCollateralRatioReceiveFixed;
        /// @notice collateral ratio for both legs, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint16 maxCollateralRatio;
        /// @notice Timestamp of most recent indicators update
        uint32 lastUpdateTimestamp;
        // @notice demand spread factor, value represents without decimals, used to calculate demand spread
        uint16 demandSpreadFactor28;
        uint16 demandSpreadFactor60;
        uint16 demandSpreadFactor90;
    }


    struct BaseSpreadsAndFixedRateCapsStorage {
        /// @notice Timestamp of most recent indicators update
        uint256 lastUpdateTimestamp;
        /// @notice spread for 28 days pay fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread28dPayFixed;
        /// @notice spread for 28 days receive fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread28dReceiveFixed;
        /// @notice spread for 60 days pay fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread60dPayFixed;
        /// @notice spread for 60 days receive fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread60dReceiveFixed;
        /// @notice spread for 90 days pay fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread90dPayFixed;
        /// @notice spread for 90 days receive fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread90dReceiveFixed;
        /// @notice fixed rate cap for 28 days pay fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap28dPayFixed;
        /// @notice fixed rate cap for 28 days receive fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap28dReceiveFixed;
        /// @notice fixed rate cap for 60 days pay fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap60dPayFixed;
        /// @notice fixed rate cap for 60 days receive fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap60dReceiveFixed;
        /// @notice fixed rate cap for 90 days pay fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap90dPayFixed;
        /// @notice fixed rate cap for 90 days receive fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap90dReceiveFixed;
    }
}

// File: lib/ipor-protocol/contracts/libraries/errors/IporErrors.sol


pragma solidity 0.8.20;

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a  guardian
    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";
}

// File: lib/ipor-protocol/contracts/libraries/StorageLib.sol


pragma solidity 0.8.20;

/// @title Storage ID's associated with the IPOR Protocol Router.
library StorageLib {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardian,
        ReentrancyStatus,
        RouterFunctionPaused,
        AmmSwapsLiquidators,
        AmmPoolsAppointedToRebalance,
        AmmPoolsParams
    }

    /// @notice Struct which contains owner address of IPOR Protocol Router.
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains appointed owner address of IPOR Protocol Router.
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Struct which contains reentrancy status of IPOR Protocol Router.
    struct ReentrancyStatusStorage {
        uint256 value;
    }

    /// @notice Struct which contains information about swap liquidators.
    /// @dev First key is an asset (pool), second key is an liquidator address in the asset pool,
    /// value is a flag to indicate whether account is a liquidator.
    /// True - account is a liquidator, False - account is not a liquidator.
    struct AmmSwapsLiquidatorsStorage {
        mapping(address => mapping(address => bool)) value;
    }

    /// @notice Struct which contains information about accounts appointed to rebalance.
    /// @dev first key - asset address, second key - account address which is allowed to rebalance in the asset pool,
    /// value - flag to indicate whether account is allowed to rebalance. True - allowed, False - not allowed.
    struct AmmPoolsAppointedToRebalanceStorage {
        mapping(address => mapping(address => bool)) value;
    }

    struct AmmPoolsParamsValue {
        /// @dev max liquidity pool balance in the asset pool, represented without 18 decimals
        uint32 maxLiquidityPoolBalance;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        /// Value represents multiplication of 1000.
        uint32 autoRebalanceThresholdInThousands;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        uint16 ammTreasuryAndAssetManagementRatio;
    }

    /// @dev key - asset address, value - struct AmmOpenSwapParamsValue
    struct AmmPoolsParamsStorage {
        mapping(address => AmmPoolsParamsValue) value;
    }

    /// @dev key - function sig, value - 1 if function is paused, 0 if not
    struct RouterFunctionPausedStorage {
        mapping(bytes4 => uint256) value;
    }

    /// @notice Gets Ipor Protocol Router owner address.
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router appointed owner address.
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router reentrancy status.
    function getReentrancyStatus() internal pure returns (ReentrancyStatusStorage storage reentrancyStatus) {
        uint256 slot = _getStorageSlot(StorageId.ReentrancyStatus);
        assembly {
            reentrancyStatus.slot := slot
        }
    }

    /// @notice Gets information if function is paused in Ipor Protocol Router.
    function getRouterFunctionPaused() internal pure returns (RouterFunctionPausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.RouterFunctionPaused);
        assembly {
            paused.slot := slot
        }
    }

    /// @notice Gets point to pause guardian storage.
    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to liquidators storage.
    /// @return store - point to liquidators storage.
    function getAmmSwapsLiquidatorsStorage() internal pure returns (AmmSwapsLiquidatorsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapsLiquidators);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to accounts appointed to rebalance storage.
    /// @return store - point to accounts appointed to rebalance storage.
    function getAmmPoolsAppointedToRebalanceStorage()
        internal
        pure
        returns (AmmPoolsAppointedToRebalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAppointedToRebalance);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to amm pools params storage.
    /// @return store - point to amm pools params storage.
    function getAmmPoolsParamsStorage() internal pure returns (AmmPoolsParamsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsParams);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

// File: lib/ipor-protocol/contracts/security/PauseManager.sol


pragma solidity 0.8.20;


/// @title Ipor Protocol Router Pause Manager library
library PauseManager {
    /// @notice Emitted when new pause guardian is added
    /// @param guardians List of addresses of guardian
    event PauseGuardiansAdded(address[] indexed guardians);

    /// @notice Emitted when pause guardian is removed
    /// @param guardians List of addresses of guardian
    event PauseGuardiansRemoved(address[] indexed guardians);

    /// @notice Checks if account is Ipor Protocol Router pause guardian
    /// @param account Address of guardian
    /// @return true if account is Ipor Protocol Router pause guardian
    function isPauseGuardian(address account) internal view returns (bool) {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[account];
    }

    /// @notice Adds Ipor Protocol Router pause guardian
    /// @param newGuardians Addresses of guardians
    function addPauseGuardians(address[] calldata newGuardians) internal {
        uint256 length = newGuardians.length;
        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[newGuardians[i]] = true;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansAdded(newGuardians);
    }

    /// @notice Removes Ipor Protocol Router pause guardian
    /// @param guardians Addresses of guardians
    function removePauseGuardians(address[] calldata guardians) internal {
        uint256 length = guardians.length;

        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[guardians[i]] = false;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansRemoved(guardians);
    }
}

// File: lib/ipor-protocol/contracts/libraries/errors/IporRiskManagementOracleErrors.sol


pragma solidity 0.8.20;

library IporRiskManagementOracleErrors {
    // 700-799- risk management oracle
    /// @notice Asset address not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_700";

    /// @notice Cannot add new asset to asset list, because already exists
    string public constant CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_701";

    /// @notice The caller must be the IporRiskManagementOracle updater
    string public constant CALLER_NOT_UPDATER = "IPOR_702";
}

// File: lib/ipor-protocol/contracts/interfaces/IProxyImplementation.sol


pragma solidity 0.8.20;

/// @title Technical interface for reading data related to the UUPS proxy pattern in Ipor Protocol.
interface IProxyImplementation {
    /// @notice Retrieves the address of the implementation contract for UUPS proxy.
    /// @return The address of the implementation contract.
    /// @dev The function returns the value stored in the implementation storage slot.
    function getImplementation() external view returns (address);
}

// File: lib/ipor-protocol/contracts/interfaces/types/IporRiskManagementOracleTypes.sol


pragma solidity 0.8.20;

/// @title Structs used in IporRiskManagementOracle smart contract
library IporRiskManagementOracleTypes {
    //@notice Risk Indicators Structure for a given asset
    struct RiskIndicators {
        /// @notice maximum notional value for pay fixed leg, 1 = 10k
        uint256 maxNotionalPayFixed;
        /// @notice maximum notional value for receive fixed leg, 1 = 10k
        uint256 maxNotionalReceiveFixed;
        /// @notice maximum collateral ratio for pay fixed leg, 1 = 0.01%
        uint256 maxCollateralRatioPayFixed;
        /// @notice maximum collateral ratio for receive fixed leg, 1 = 0.01%
        uint256 maxCollateralRatioReceiveFixed;
        /// @notice maximum collateral ratio for both legs, 1 = 0.01%
        uint256 maxCollateralRatio;
        // @notice demand spread factor, value represents without decimals, used to calculate demand spread, max number 2^16-1
        uint256 demandSpreadFactor28;
        uint256 demandSpreadFactor60;
        uint256 demandSpreadFactor90;
    }

    //@notice Base Spreads And Fixed Rate Caps Structure for a given asset, both legs and all maturities
    struct BaseSpreadsAndFixedRateCaps {
        /// @notice spread for 28 days pay fixed swap
        int256 spread28dPayFixed;
        /// @notice spread for 28 days receive fixed swap
        int256 spread28dReceiveFixed;
        /// @notice spread for 60 days pay fixed swap
        int256 spread60dPayFixed;
        /// @notice spread for 60 days receive fixed swap
        int256 spread60dReceiveFixed;
        /// @notice spread for 90 days pay fixed swap
        int256 spread90dPayFixed;
        /// @notice spread for 90 days receive fixed swap
        int256 spread90dReceiveFixed;
        /// @notice fixed rate cap for 28 days pay fixed swap
        uint256 fixedRateCap28dPayFixed;
        /// @notice fixed rate cap for 28 days receive fixed swap
        uint256 fixedRateCap28dReceiveFixed;
        /// @notice fixed rate cap for 60 days pay fixed swap
        uint256 fixedRateCap60dPayFixed;
        /// @notice fixed rate cap for 60 days receive fixed swap
        uint256 fixedRateCap60dReceiveFixed;
        /// @notice fixed rate cap for 90 days pay fixed swap
        uint256 fixedRateCap90dPayFixed;
        /// @notice fixed rate cap for 90 days receive fixed swap
        uint256 fixedRateCap90dReceiveFixed;
    }
}

// File: lib/ipor-protocol/contracts/interfaces/types/IporTypes.sol


pragma solidity 0.8.20;

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapTenor {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }

    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct  AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct AmmBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transferred to Asset Management Vault (AssetManagement)
        uint256 vault;
    }

    struct AmmBalancesForOpenSwapMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
        /// @notice Liquidity Pool Balance.
        uint256 liquidityPool;
    }

    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
    }
}

// File: lib/ipor-protocol/contracts/interfaces/IIporRiskManagementOracle.sol


pragma solidity 0.8.20;



interface IIporRiskManagementOracle {
    /// @notice event emitted when risk indicators are updated. Values and rates are not represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxCollateralRatioPayFixed maximum collateral ratio for pay fixed leg, 1 = 0.01%
    /// @param maxCollateralRatioReceiveFixed maximum collateral ratio for receive fixed leg, 1 = 0.01%
    /// @param maxCollateralRatio maximum collateral ratio for both legs, 1 = 0.01%
    /// @param demandSpreadFactor28 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor60 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor90 demand spread factor, value represents without decimals, used to calculate demand spread
    event RiskIndicatorsUpdated(
        address indexed asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    );

    /// @notice event emitted when base spreads are updated. Rates are represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param baseSpreads28dPayFixed spread for 28 days pay fixed swap
    /// @param baseSpreads28dReceiveFixed spread for 28 days receive fixed swap
    /// @param baseSpreads60dPayFixed spread for 60 days pay fixed swap
    /// @param baseSpreads60dReceiveFixed spread for 60 days receive fixed swap
    /// @param baseSpreads90dPayFixed spread for 90 days pay fixed swap
    /// @param baseSpreads90dReceiveFixed spread for 90 days receive fixed swap
    event BaseSpreadsUpdated(
        address indexed asset,
        int256 baseSpreads28dPayFixed,
        int256 baseSpreads28dReceiveFixed,
        int256 baseSpreads60dPayFixed,
        int256 baseSpreads60dReceiveFixed,
        int256 baseSpreads90dPayFixed,
        int256 baseSpreads90dReceiveFixed
    );

    /// @notice event emitted when base spreads are updated. Rates are represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param fixedRateCap28dPayFixed fixed rate cap for 28 days pay fixed swap
    /// @param fixedRateCap28dReceiveFixed fixed rate cap for 28 days receive fixed swap
    /// @param fixedRateCap60dPayFixed fixed rate cap for 60 days pay fixed swap
    /// @param fixedRateCap60dReceiveFixed fixed rate cap for 60 days receive fixed swap
    /// @param fixedRateCap90dPayFixed fixed rate cap for 90 days pay fixed swap
    /// @param fixedRateCap90dReceiveFixed fixed rate cap for 90 days receive fixed swap
    event FixedRateCapsUpdated(
        address indexed asset,
        uint256 fixedRateCap28dPayFixed,
        uint256 fixedRateCap28dReceiveFixed,
        uint256 fixedRateCap60dPayFixed,
        uint256 fixedRateCap60dReceiveFixed,
        uint256 fixedRateCap90dPayFixed,
        uint256 fixedRateCap90dReceiveFixed
    );

    /// @notice event emitted when new asset is added
    /// @param asset underlying / stablecoin address
    event IporRiskManagementOracleAssetAdded(address indexed asset);

    /// @notice event emitted when asset is removed
    /// @param asset underlying / stablecoin address
    event IporRiskManagementOracleAssetRemoved(address indexed asset);

    /// @notice event emitted when new updater is added
    /// @param updater address
    event IporRiskManagementOracleUpdaterAdded(address indexed updater);

    /// @notice event emitted when updater is removed
    /// @param updater address
    event IporRiskManagementOracleUpdaterRemoved(address indexed updater);

    /// @notice Returns current version of IIporRiskManagementOracle's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IIporRiskManagementOracle version
    function getVersion() external pure returns (uint256);

    /// @notice Gets risk indicators and base spread for a given asset, swap direction and tenor. Rates represented in 6 decimals. 1 = 0.0001%
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @param direction swap direction, 0 = pay fixed, 1 = receive fixed
    /// @param tenor swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
    /// @return maxNotionalPerLeg maximum notional value for given leg
    /// @return maxCollateralRatioPerLeg maximum collateral ratio for given leg
    /// @return maxCollateralRatio maximum collateral ratio for both legs
    /// @return baseSpreadPerLeg spread for given direction and tenor
    /// @return fixedRateCapPerLeg fixed rate cap for given direction and tenor
    /// @return demandSpreadFactor demand spread factor, value represents without decimals, used to calculate demand spread
    function getOpenSwapParameters(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    )
        external
        view
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxCollateralRatioPerLeg,
            uint256 maxCollateralRatio,
            int256 baseSpreadPerLeg,
            uint256 fixedRateCapPerLeg,
            uint256 demandSpreadFactor
        );

    /// @notice Gets risk indicators for a given asset. Amounts and rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return maxNotionalPayFixed maximum notional value for pay fixed leg
    /// @return maxNotionalReceiveFixed maximum notional value for receive fixed leg
    /// @return maxCollateralRatioPayFixed maximum collateral ratio for pay fixed leg
    /// @return maxCollateralRatioReceiveFixed maximum collateral ratio for receive fixed leg
    /// @return maxCollateralRatio maximum collateral ratio for both legs
    /// @return lastUpdateTimestamp Last risk indicators update done by off-chain service
    /// @return demandSpreadFactor demand spread factor, value represents without decimals, used to calculate demand spread
    function getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor
    )
        external
        view
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor
        );

    /// @notice Gets base spreads for a given asset. Rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return lastUpdateTimestamp Last base spreads update done by off-chain service
    /// @return spread28dPayFixed spread for 28 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread28dReceiveFixed spread for 28 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread60dPayFixed spread for 60 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread60dReceiveFixed spread for 60 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread90dPayFixed spread for 90 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread90dReceiveFixed spread for 90 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    function getBaseSpreads(
        address asset
    )
        external
        view
        returns (
            uint256 lastUpdateTimestamp,
            int256 spread28dPayFixed,
            int256 spread28dReceiveFixed,
            int256 spread60dPayFixed,
            int256 spread60dReceiveFixed,
            int256 spread90dPayFixed,
            int256 spread90dReceiveFixed
        );

    /// @notice Gets fixed rate cap for a given asset. Rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return lastUpdateTimestamp Last base spreads update done by off-chain service
    /// @return fixedRateCap28dPayFixed fixed rate cap for 28 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap28dReceiveFixed fixed rate cap for 28 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap60dPayFixed fixed rate cap for 60 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap60dReceiveFixed fixed rate cap for 60 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap90dPayFixed fixed rate cap for 90 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap90dReceiveFixed fixed rate cap for 90 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    function getFixedRateCaps(
        address asset
    )
        external
        view
        returns (
            uint256 lastUpdateTimestamp,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        );

    /// @notice Checks if given asset is supported by IPOR Protocol.
    /// @param asset underlying / stablecoin address
    function isAssetSupported(address asset) external view returns (bool);

    /// @notice Checks if given account is an Updater.
    /// @param account account for checking
    /// @return 0 if account is not updater, 1 if account is updater.
    function isUpdater(address account) external view returns (uint256);

    /// @notice Updates risk indicators for a given asset. Values and rates are not represented in 18 decimals.
    /// @dev Emmits {RiskIndicatorsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxCollateralRatioPayFixed maximum collateral ratio for pay fixed leg, 1 = 0.01%
    /// @param maxCollateralRatioReceiveFixed maximum collateral ratio for receive fixed leg, 1 = 0.01%
    /// @param maxCollateralRatio maximum collateral ratio for both legs, 1 = 0.01%
    /// @param demandSpreadFactor28 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor60 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor90 demand spread factor, value represents without decimals, used to calculate demand spread
    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    ) external;

    /// @notice Updates base spreads and fixed rate caps for a given asset. Rates are not represented in 18 decimals
    /// @dev Emmits {BaseSpreadsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param baseSpreadsAndFixedRateCaps base spreads and fixed rate caps for a given asset
    function updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external;

    /// @notice Adds asset which IPOR Protocol will support. Function available only for Owner.
    /// @param asset underlying / stablecoin address which will be supported by IPOR Protocol.
    /// @param riskIndicators risk indicators
    /// @param baseSpreadsAndFixedRateCaps base spread and fixed rate cap for each maturities and both legs
    function addAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external;

    /// @notice Removes asset which IPOR Protocol will not support. Function available only for Owner.
    /// @param asset  underlying / stablecoin address which current is supported by IPOR Protocol.
    function removeAsset(address asset) external;

    /// @notice Adds new Updater. Updater has right to update indicators. Function available only for Owner.
    /// @param newUpdater new updater address
    function addUpdater(address newUpdater) external;

    /// @notice Removes Updater. Function available only for Owner.
    /// @param updater updater address
    function removeUpdater(address updater) external;
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: lib/ipor-protocol/contracts/security/IporOwnableUpgradeable.sol


pragma solidity 0.8.20;



/// @title Extended version of OpenZeppelin OwnableUpgradeable contract with appointed owner
abstract contract IporOwnableUpgradeable is OwnableUpgradeable {
    address private _appointedOwner;

    /// @notice Emitted when account is appointed to transfer ownership
    /// @param appointedOwner Address of appointed owner
    event AppointedToTransferOwnership(address indexed appointedOwner);

    modifier onlyAppointedOwner() {
        require(_appointedOwner == msg.sender, IporErrors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }

    /// @notice Oppoint account to transfer ownership
    /// @param appointedOwner Address of appointed owner
    function transferOwnership(address appointedOwner) public override onlyOwner {
        require(appointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        _appointedOwner = appointedOwner;
        emit AppointedToTransferOwnership(appointedOwner);
    }

    /// @notice Confirm transfer ownership
    /// @dev This is real transfer ownership in second step by appointed account
    function confirmTransferOwnership() external onlyAppointedOwner {
        _appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    /// @notice Renounce ownership
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
        _appointedOwner = address(0);
    }
}

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;







/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;




/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: lib/ipor-protocol/contracts/oracles/IporRiskManagementOracle.sol


pragma solidity 0.8.20;












/**
 * @title Ipor Risk Management Oracle contract
 *
 * @author IPOR Labs
 */
contract IporRiskManagementOracle is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IIporRiskManagementOracle,
    IIporContractCommonGov,
    IProxyImplementation
{
    using SafeCast for uint256;
    using SafeCast for int256;

    mapping(address => uint256) internal _updaters;
    mapping(address => IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage) internal _indicators;

    /// @dev 0 - 31 bytes - lastUpdateTimestamp - uint32 - number of seconds since 1970-01-01T00:00:00Z
    /// @dev 32 - 55 bytes - baseSpread28dPayFixed - int24 - base spread for 28 days period for pay fixed leg,
    /// @dev    - on 32th position it is a sing - 1 means negative, 0 means positive
    /// @dev 56 - 79 bytes - baseSpread28dReceiveFixed - int24 - base spread for 28 days period for receive fixed leg,
    /// @dev    - on 56 position it is a sing - 1 means negative, 0 means positive
    /// @dev 80 - 103 bytes - baseSpread60dPayFixed - int24 - base spread for 60 days period for pay fixed leg,
    /// @dev    - on 80 position it is a sing - 1 means negative, 0 means positive
    /// @dev 104 - 127 bytes - baseSpread60dReceiveFixed - int24 - base spread for 60 days period for receive fixed leg,
    /// @dev    - on 104 position it is a sing - 1 means negative, 0 means positive
    /// @dev 128 - 151 bytes - baseSpread90dPayFixed - int24 - base spread for 90 days period for pay fixed leg,
    /// @dev   - on 128 position it is a sing - 1 means negative, 0 means positive
    /// @dev 152 - 175 bytes - baseSpread90dReceiveFixed - int24 - base spread for 90 days period for receive fixed leg,
    /// @dev    - on 152 position it is a sing - 1 means negative, 0 means positive
    /// @dev 176 - 187 bytes - fixedRateCap28dPayFixed - uint12 - fixed rate cap for 28 days period for pay fixed leg,
    /// @dev 188 - 199 bytes - fixedRateCap28dReceiveFixed - uint12 - fixed rate cap for 28 days period for receive fixed leg,
    /// @dev 200 - 211 bytes - fixedRateCap60dPayFixed - uint12 - fixed rate cap for 60 days period for pay fixed leg,
    /// @dev 212 - 223 bytes - fixedRateCap60dReceiveFixed - uint12 - fixed rate cap for 60 days period for receive fixed leg,
    /// @dev 224 - 235 bytes - fixedRateCap90dPayFixed - uint12 - fixed rate cap for 90 days period for pay fixed leg,
    mapping(address => bytes32) internal _baseSpreadsAndFixedRateCaps;

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyUpdater() {
        require(_updaters[msg.sender] == 1, IporRiskManagementOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory assets,
        IporRiskManagementOracleTypes.RiskIndicators[] calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[] calldata baseSpreadsAndFixedRateCaps
    ) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        require(
            assetsLength == riskIndicators.length && assetsLength == baseSpreadsAndFixedRateCaps.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        for (uint256 i; i != assetsLength; ) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(
                riskIndicators[i].demandSpreadFactor28 != 0 &&
                    riskIndicators[i].demandSpreadFactor60 != 0 &&
                    riskIndicators[i].demandSpreadFactor90 != 0,
                IporErrors.VALUE_NOT_GREATER_THAN_ZERO
            );
            _indicators[assets[i]] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
                riskIndicators[i].maxNotionalPayFixed.toUint64(),
                riskIndicators[i].maxNotionalReceiveFixed.toUint64(),
                riskIndicators[i].maxCollateralRatioPayFixed.toUint16(),
                riskIndicators[i].maxCollateralRatioReceiveFixed.toUint16(),
                riskIndicators[i].maxCollateralRatio.toUint16(),
                block.timestamp.toUint32(),
                riskIndicators[i].demandSpreadFactor28.toUint16(),
                riskIndicators[i].demandSpreadFactor60.toUint16(),
                riskIndicators[i].demandSpreadFactor90.toUint16()
            );

            emit RiskIndicatorsUpdated(
                assets[i],
                riskIndicators[i].maxNotionalPayFixed,
                riskIndicators[i].maxNotionalReceiveFixed,
                riskIndicators[i].maxCollateralRatioPayFixed,
                riskIndicators[i].maxCollateralRatioReceiveFixed,
                riskIndicators[i].maxCollateralRatio,
                riskIndicators[i].demandSpreadFactor28,
                riskIndicators[i].demandSpreadFactor60,
                riskIndicators[i].demandSpreadFactor90
            );

            _baseSpreadsAndFixedRateCaps[assets[i]] = _baseSpreadsAndFixedRateCapsStorageToBytes32(
                IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
                    block.timestamp,
                    baseSpreadsAndFixedRateCaps[i].spread28dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].spread28dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].spread60dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].spread60dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].spread90dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].spread90dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap28dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap28dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap60dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap60dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap90dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap90dReceiveFixed
                )
            );

            emit BaseSpreadsUpdated(
                assets[i],
                baseSpreadsAndFixedRateCaps[i].spread28dPayFixed,
                baseSpreadsAndFixedRateCaps[i].spread28dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].spread60dPayFixed,
                baseSpreadsAndFixedRateCaps[i].spread60dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].spread90dPayFixed,
                baseSpreadsAndFixedRateCaps[i].spread90dReceiveFixed
            );

            emit FixedRateCapsUpdated(
                assets[i],
                baseSpreadsAndFixedRateCaps[i].fixedRateCap28dPayFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap28dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap60dPayFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap60dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap90dPayFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap90dReceiveFixed
            );
            unchecked {
                ++i;
            }
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
    }

    function getOpenSwapParameters(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    )
        external
        view
        override
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxCollateralRatioPerLeg,
            uint256 maxCollateralRatio,
            int256 baseSpreadPerLeg,
            uint256 fixedRateCapPerLeg,
            uint256 demandSpreadFactor
        )
    {
        (
            maxNotionalPerLeg,
            maxCollateralRatioPerLeg,
            maxCollateralRatio,
            demandSpreadFactor
        ) = _getRiskIndicatorsPerLeg(asset, direction, tenor);
        (baseSpreadPerLeg, fixedRateCapPerLeg) = _getSpread(asset, direction, tenor);
        /// @dev baseSpreadPerLeg is a value in percentage with 4 decimals (example: 1 = 0.0001%), so we need to multiply by 1e12 to achieve value in 18 decimals.
        /// @dev fixedRateCapPerLeg is a value in percentage with 2 decimals (example: 100 = 1%, 1 = 0.01%), so we need to multiply by 1e14 to achieve value in 18 decimals.
        return (
            maxNotionalPerLeg,
            maxCollateralRatioPerLeg,
            maxCollateralRatio,
            baseSpreadPerLeg * 1e12,
            fixedRateCapPerLeg * 1e14,
            demandSpreadFactor
        );
    }

    function getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor
    )
        external
        view
        override
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor
        )
    {
        return _getRiskIndicators(asset, tenor);
    }

    function getBaseSpreads(
        address asset
    )
        external
        view
        override
        returns (
            uint256 lastUpdateTimestamp,
            int256 spread28dPayFixed,
            int256 spread28dReceiveFixed,
            int256 spread60dPayFixed,
            int256 spread60dReceiveFixed,
            int256 spread90dPayFixed,
            int256 spread90dReceiveFixed
        )
    {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );
        /// @dev Spread value is represented in percentage with 4 decimals (example: 1 = 0.0001%, more details check in structure description `IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage`),
        /// in return values are represented in 18 decimals, so we need to multiply by 1e12.
        return (
            uint256(baseSpreadsAndFixedRateCaps.lastUpdateTimestamp),
            int256(baseSpreadsAndFixedRateCaps.spread28dPayFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread28dReceiveFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread60dPayFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread60dReceiveFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread90dPayFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread90dReceiveFixed) * 1e12
        );
    }

    function getFixedRateCaps(
        address asset
    )
        external
        view
        override
        returns (
            uint256 lastUpdateTimestamp,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        )
    {
        return _getFixedRateCaps(asset);
    }

    function isAssetSupported(address asset) external view override returns (bool) {
        return _indicators[asset].lastUpdateTimestamp > 0;
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    ) external override onlyUpdater whenNotPaused {
        require(
            demandSpreadFactor28 != 0 &&
            demandSpreadFactor60 != 0 &&
            demandSpreadFactor90 != 0,
            IporErrors.VALUE_NOT_GREATER_THAN_ZERO
        );
        _updateRiskIndicators(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxCollateralRatioPayFixed,
            maxCollateralRatioReceiveFixed,
            maxCollateralRatio,
            demandSpreadFactor28,
            demandSpreadFactor60,
            demandSpreadFactor90
        );
    }

    function updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external override onlyUpdater whenNotPaused {
        _updateBaseSpreadsAndFixedRateCaps(asset, baseSpreadsAndFixedRateCaps);
    }

    function addAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indicators[asset].lastUpdateTimestamp == 0,
            IporRiskManagementOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS
        );

        _indicators[asset] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
            riskIndicators.maxNotionalPayFixed.toUint64(),
            riskIndicators.maxNotionalReceiveFixed.toUint64(),
            riskIndicators.maxCollateralRatioPayFixed.toUint16(),
            riskIndicators.maxCollateralRatioReceiveFixed.toUint16(),
            riskIndicators.maxCollateralRatio.toUint16(),
            block.timestamp.toUint32(),
            riskIndicators.demandSpreadFactor28.toUint16(),
            riskIndicators.demandSpreadFactor60.toUint16(),
            riskIndicators.demandSpreadFactor90.toUint16()
        );

        _baseSpreadsAndFixedRateCaps[asset] = _baseSpreadsAndFixedRateCapsStorageToBytes32(
            IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
                block.timestamp,
                baseSpreadsAndFixedRateCaps.spread28dPayFixed,
                baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread60dPayFixed,
                baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread90dPayFixed,
                baseSpreadsAndFixedRateCaps.spread90dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
            )
        );

        emit IporRiskManagementOracleAssetAdded(asset);
    }

    function removeAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indicators[asset].lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        delete _indicators[asset];
        emit IporRiskManagementOracleAssetRemoved(asset);
    }

    function addUpdater(address updater) external override onlyOwner {
        require(updater != address(0), IporErrors.WRONG_ADDRESS);

        _updaters[updater] = 1;
        emit IporRiskManagementOracleUpdaterAdded(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        require(updater != address(0), IporErrors.WRONG_ADDRESS);

        _updaters[updater] = 0;
        emit IporRiskManagementOracleUpdaterRemoved(updater);
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor
    )
        internal
        view
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor
        )
    {
        IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage memory indicators = _indicators[asset];
        require(indicators.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            demandSpreadFactor = uint256(indicators.demandSpreadFactor28);
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            demandSpreadFactor = uint256(indicators.demandSpreadFactor60);
        } else {
            demandSpreadFactor = uint256(indicators.demandSpreadFactor90);
        }

        /// @dev Multiplication by 1e22 or by 1e14 is needed to achieve WAD number used internally in calculations (value represented in 18 decimals)
        /// For more information check description for `IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage`
        return (
            uint256(indicators.maxNotionalPayFixed) * 1e22, /// @dev field represents number without decimals and with multiplication of 10_000,  1 = 10k
            uint256(indicators.maxNotionalReceiveFixed) * 1e22, /// @dev field represents number without decimals and with multiplication of 10_000,  1 = 10k
            uint256(indicators.maxCollateralRatioPayFixed) * 1e14, /// @dev Value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
            uint256(indicators.maxCollateralRatioReceiveFixed) * 1e14, /// @dev Value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
            uint256(indicators.maxCollateralRatio) * 1e14, /// @dev Value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
            uint256(indicators.lastUpdateTimestamp),
            demandSpreadFactor
        );
    }

    function _getRiskIndicatorsPerLeg(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    )
        internal
        view
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxCollateralRatioPerLeg,
            uint256 maxCollateralRatio,
            uint256 demandSpreadFactor
        )
    {
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatioBothLegs,
            ,
            uint256 demandSpreadFactorStorage
        ) = _getRiskIndicators(asset, tenor);

        if (direction == 0) {
            return (
                maxNotionalPayFixed,
                maxCollateralRatioPayFixed,
                maxCollateralRatioBothLegs,
                demandSpreadFactorStorage
            );
        } else {
            return (
                maxNotionalReceiveFixed,
                maxCollateralRatioReceiveFixed,
                maxCollateralRatioBothLegs,
                demandSpreadFactorStorage
            );
        }
    }

    /// @return int256 - base spread, value represents percentage with 4 decimals, example: 1 = 0.0001%
    /// @return uint256 - fixed rate cap, value represents percentage with 2 decimals, example: 100 = 1%
    function _getSpread(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    ) internal view returns (int256, uint256) {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            if (direction == 0) {
                return (
                    baseSpreadsAndFixedRateCaps.spread28dPayFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed
                );
            } else {
                return (
                    baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed
                );
            }
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            if (direction == 0) {
                return (
                    baseSpreadsAndFixedRateCaps.spread60dPayFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed
                );
            } else {
                return (
                    baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed
                );
            }
        } else {
            if (direction == 0) {
                return (
                    baseSpreadsAndFixedRateCaps.spread90dPayFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed
                );
            } else {
                return (
                    baseSpreadsAndFixedRateCaps.spread90dReceiveFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
                );
            }
        }
    }

    function _getFixedRateCaps(
        address asset
    )
        internal
        view
        returns (
            uint256 lastUpdateTimestamp,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        )
    {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        /// @dev Cap values represent percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        /// To achieve WAD number used internally in calculations (value represented in 18 decimals) we need to multiply by 1e14
        return (
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed * 1e14
        );
    }

    function _updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    ) internal {
        IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage memory indicators = _indicators[asset];

        require(indicators.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        _indicators[asset] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
            maxNotionalPayFixed.toUint64(),
            maxNotionalReceiveFixed.toUint64(),
            maxCollateralRatioPayFixed.toUint16(),
            maxCollateralRatioReceiveFixed.toUint16(),
            maxCollateralRatio.toUint16(),
            block.timestamp.toUint32(),
            demandSpreadFactor28.toUint16(),
            demandSpreadFactor60.toUint16(),
            demandSpreadFactor90.toUint16()
        );

        emit RiskIndicatorsUpdated(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxCollateralRatioPayFixed,
            maxCollateralRatioReceiveFixed,
            maxCollateralRatio,
            demandSpreadFactor28,
            demandSpreadFactor60,
            demandSpreadFactor90
        );
    }

    function _updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) internal {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCapsStorage = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );

        require(
            baseSpreadsAndFixedRateCapsStorage.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        _baseSpreadsAndFixedRateCaps[asset] = _baseSpreadsAndFixedRateCapsStorageToBytes32(
            IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
                block.timestamp,
                baseSpreadsAndFixedRateCaps.spread28dPayFixed,
                baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread60dPayFixed,
                baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread90dPayFixed,
                baseSpreadsAndFixedRateCaps.spread90dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
            )
        );

        emit BaseSpreadsUpdated(
            asset,
            baseSpreadsAndFixedRateCaps.spread28dPayFixed,
            baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
            baseSpreadsAndFixedRateCaps.spread60dPayFixed,
            baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
            baseSpreadsAndFixedRateCaps.spread90dPayFixed,
            baseSpreadsAndFixedRateCaps.spread90dReceiveFixed
        );

        emit FixedRateCapsUpdated(
            asset,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
        );
    }

    function _baseSpreadsAndFixedRateCapsStorageToBytes32(
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage memory toSave
    ) internal pure returns (bytes32 result) {
        require(toSave.lastUpdateTimestamp < type(uint32).max, "lastUpdateTimestamp overflow");
        require(
            -type(int24).max < toSave.spread28dPayFixed && toSave.spread28dPayFixed < type(int24).max,
            "spread28dPayFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread28dReceiveFixed && toSave.spread28dReceiveFixed < type(int24).max,
            "spread28dReceiveFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread60dPayFixed && toSave.spread60dPayFixed < type(int24).max,
            "spread60dPayFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread60dReceiveFixed && toSave.spread60dReceiveFixed < type(int24).max,
            "spread60dReceiveFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread90dPayFixed && toSave.spread90dPayFixed < type(int24).max,
            "spread90dPayFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread90dReceiveFixed && toSave.spread90dReceiveFixed < type(int24).max,
            "spread90dReceiveFixed overflow"
        );
        require(toSave.fixedRateCap28dPayFixed < 2 ** 12, "fixedRateCap28dPayFixed overflow");
        require(toSave.fixedRateCap28dReceiveFixed < 2 ** 12, "fixedRateCap28dReceiveFixed overflow");
        require(toSave.fixedRateCap60dPayFixed < 2 ** 12, "fixedRateCap60dPayFixed overflow");
        require(toSave.fixedRateCap60dReceiveFixed < 2 ** 12, "fixedRateCap60dReceiveFixed overflow");
        require(toSave.fixedRateCap90dPayFixed < 2 ** 12, "fixedRateCap90dPayFixed overflow");
        require(toSave.fixedRateCap90dReceiveFixed < 2 ** 12, "fixedRateCap90dReceiveFixed overflow");

        assembly {
            function abs(value) -> y {
                switch slt(value, 0)
                case true {
                    y := sub(0, value)
                }
                case false {
                    y := value
                }
            }

            result := add(
                mload(toSave),
                add(
                    shl(32, slt(mload(add(toSave, 32)), 0)),
                    add(
                        shl(33, abs(mload(add(toSave, 32)))),
                        add(
                            shl(56, slt(mload(add(toSave, 64)), 0)),
                            add(
                                shl(57, abs(mload(add(toSave, 64)))),
                                add(
                                    shl(80, slt(mload(add(toSave, 96)), 0)), //spread60dPayFixed
                                    add(
                                        shl(81, abs(mload(add(toSave, 96)))), //spread60dPayFixed
                                        add(
                                            shl(104, slt(mload(add(toSave, 128)), 0)), //spread60dReceiveFixed
                                            add(
                                                shl(105, abs(mload(add(toSave, 128)))), //spread60dReceiveFixed
                                                add(
                                                    shl(128, slt(mload(add(toSave, 160)), 0)), //spread90dPayFixed
                                                    add(
                                                        shl(129, abs(mload(add(toSave, 160)))), //spread90dPayFixed
                                                        add(
                                                            shl(152, slt(mload(add(toSave, 192)), 0)), //spread90dReceiveFixed
                                                            add(
                                                                shl(153, abs(mload(add(toSave, 192)))), //spread90dReceiveFixed
                                                                add(
                                                                    shl(176, mload(add(toSave, 224))), //fixedRateCap28dPayFixed
                                                                    add(
                                                                        shl(188, mload(add(toSave, 256))), //fixedRateCap28dReceiveFixed
                                                                        add(
                                                                            shl(200, mload(add(toSave, 288))), //fixedRateCap60dPayFixed
                                                                            add(
                                                                                shl(212, mload(add(toSave, 320))), //fixedRateCap60dReceiveFixed
                                                                                add(
                                                                                    shl(224, mload(add(toSave, 352))), //fixedRateCap90dPayFixed
                                                                                    shl(236, mload(add(toSave, 384))) //fixedRateCap90dReceiveFixed
                                                                                )
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        }
        return result;
    }

    function _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
        bytes32 toSave
    ) internal pure returns (IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage memory result) {
        assembly {
            function convertToInt(sign, value) -> y {
                switch sign
                case 0 {
                    y := value
                }
                case 1 {
                    y := sub(0, value)
                }
            }
            mstore(result, and(toSave, 0xFFFFFFFF)) // lastUpdateTimestamp
            mstore(add(result, 32), convertToInt(and(shr(32, toSave), 0x1), and(shr(33, toSave), 0x7FFFFF))) // spread28dPayFixed
            mstore(add(result, 64), convertToInt(and(shr(56, toSave), 0x1), and(shr(57, toSave), 0x7FFFFF))) // spread28dReceiveFixed
            mstore(add(result, 96), convertToInt(and(shr(80, toSave), 0x1), and(shr(81, toSave), 0x7FFFFF))) // spread60dPayFixed
            mstore(add(result, 128), convertToInt(and(shr(104, toSave), 0x1), and(shr(105, toSave), 0x7FFFFF))) // spread60dReceiveFixed
            mstore(add(result, 160), convertToInt(and(shr(128, toSave), 0x1), and(shr(129, toSave), 0x7FFFFF))) // spread90dPayFixed
            mstore(add(result, 192), convertToInt(and(shr(152, toSave), 0x1), and(shr(153, toSave), 0x7FFFFF))) // spread90dReceiveFixed
            mstore(add(result, 224), and(shr(176, toSave), 0xFFF)) // fixedRateCap28dPayFixed
            mstore(add(result, 256), and(shr(188, toSave), 0xFFF)) // fixedRateCap28dReceiveFixed
            mstore(add(result, 288), and(shr(200, toSave), 0xFFF)) // fixedRateCap60dPayFixed
            mstore(add(result, 320), and(shr(212, toSave), 0xFFF)) // fixedRateCap60dReceiveFixed
            mstore(add(result, 352), and(shr(224, toSave), 0xFFF)) // fixedRateCap90dPayFixed
            mstore(add(result, 384), and(shr(236, toSave), 0xFFF)) // fixedRateCap90dReceiveFixed
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}