// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";
import "./IBVault.sol";

interface IBManagedPoolFactory {
    struct NewPoolParams {
        IBVault vault;
        string name;
        string symbol;
        IERC20[] tokens;
        uint256[] normalizedWeights;
        address[] assetManagers;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        bool swapEnabledOnStart;
        bool mustAllowlistLPs;
        uint256 managementSwapFeePercentage;
    }

    struct BasePoolRights {
        bool canTransferOwnership;
        bool canChangeSwapFee;
        bool canUpdateMetadata;
    }

    struct ManagedPoolRights {
        bool canChangeWeights;
        bool canDisableSwaps;
        bool canSetMustAllowlistLPs;
        bool canSetCircuitBreakers;
        bool canChangeTokens;
    }

    function create(
        NewPoolParams memory poolParams,
        BasePoolRights memory basePoolRights,
        ManagedPoolRights memory managedPoolRights,
        uint256 minWeightChangeDuration
    ) external returns (address);
}