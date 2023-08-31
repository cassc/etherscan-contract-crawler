// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Accountant } from '../Accountant.sol';
import { Transport } from '../transport/Transport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { IntegrationDataTracker } from '../integration-data-tracker/IntegrationDataTracker.sol';
import { GmxConfig } from '../GmxConfig.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';
import { IAggregatorV3Interface } from '../interfaces/IAggregatorV3Interface.sol';
import { IValioCustomAggregator } from '../aggregators/IValioCustomAggregator.sol';

library RegistryStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Registry');

    // Cannot use struct with diamond storage,
    // as adding any extra storage slots will break the following already declared members
    // solhint-disable-next-line ordering
    struct VaultSettings {
        bool ___deprecated;
        uint ____deprecated;
        uint _____deprecated;
        uint ______deprecated;
    }

    // solhint-disable-next-line ordering
    enum AssetType {
        None,
        GMX,
        Erc20
    }

    // solhint-disable-next-line ordering
    enum AggregatorType {
        ChainlinkV3USD,
        UniswapV3Twap,
        VelodromeV2Twap,
        None // Things like gmx return a value in usd so no aggregator is needed
    }

    // solhint-disable-next-line ordering
    struct Layout {
        uint16 chainId;
        address protocolTreasury;
        address parentVaultDiamond;
        address childVaultDiamond;
        mapping(address => bool) parentVaults;
        mapping(address => bool) childVaults;
        VaultSettings _deprecated;
        Accountant accountant;
        Transport transport;
        IntegrationDataTracker integrationDataTracker;
        GmxConfig gmxConfig;
        mapping(ExecutorIntegration => address) executors;
        // Price get will revert if the price hasn't be updated in the below time
        uint256 chainlinkTimeout;
        mapping(AssetType => address) valuers;
        mapping(AssetType => address) redeemers;
        mapping(address => AssetType) assetTypes;
        // All must return USD price and be 8 decimals
        mapping(address => IAggregatorV3Interface) chainlinkV3USDAggregators;
        mapping(address => bool) deprecatedAssets; // Assets that cannot be traded into, only out of
        address zeroXExchangeRouter;
        uint zeroXMaximumSingleSwapPriceImpactBips;
        bool canChangeManager;
        // The number of assets that can be active at once for a vault
        // This is important so withdraw processing doesn't consume > max gas
        uint maxActiveAssets;
        uint depositLockupTime;
        uint livelinessThreshold;
        mapping(VaultRiskProfile => uint) maxCpitBips;
        uint maxSingleActionImpactBips;
        uint minDepositAmount;
        bool canChangeManagerFees;
        // Assets that can be deposited into the vault
        mapping(address => bool) depositAssets;
        uint vaultValueCap;
        bool managerWhitelistEnabled;
        mapping(address => bool) allowedManagers;
        bool investorWhitelistEnabled;
        mapping(address => bool) allowedInvestors;
        address withdrawAutomator;
        mapping(address => IValioCustomAggregator) DEPRECATED_valioCustomUSDAggregators;
        address[] parentVaultList;
        address[] childVaultList;
        address[] assetList;
        uint maxDepositAmount;
        uint protocolFeeBips;
        mapping(address => AggregatorType) assetAggregatorType;
        // All must return USD price and be 8 decimals
        mapping(AggregatorType => IValioCustomAggregator) valioCustomUSDAggregators;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}