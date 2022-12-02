// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IController, GammaTypes} from "./ribbon-v2-contracts/interfaces/GammaInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Checks that RibbonV2 Theta Vaults do not lose 90% of their assets
/// @notice Ante Test to check if a catastrophic failure has occured in RibbonV2
contract AnteRibbonV2UpdatableThetaVaultPlungeTest is Ownable, AnteTest("RibbonV2 Theta Vaults don't lose 90% of TVL") {
    /// @notice Emitted when test owner adds a vault to check
    /// @param vault The address of the vault added
    /// @param vaultAsset The address of the ERC20 token used by the vault
    /// @param initialThreshold the initial failure threshold of the new vault
    event AnteRibbonTestVaultAdded(address indexed vault, address vaultAsset, uint256 initialThreshold);

    /// @notice Emitted when test owner commits a failure thresholds update
    /// @param vault The address of the vault to be updated
    /// @param oldThreshold old failure threshold
    /// @param newThreshold new failure threshold
    event AnteRibbonTestPendingUpdate(address indexed vault, uint256 oldThreshold, uint256 newThreshold);

    /// @notice Emitted when test owner updates test vaults/thresholds
    /// @param vault The address of the updated vault
    /// @param oldThreshold old failure threshold
    /// @param newThreshold new failure threshold
    event AnteRibbonTestUpdated(address indexed vault, uint256 oldThreshold, uint256 newThreshold);
    /// Opyn Controller
    IController internal controller = IController(0x4ccc2339F87F6c59c6893E1A678c2266cA58dC72);

    /// Array of Theta Vaults checked by this test
    address[] public thetaVaults;

    /// Mapping of asset to check for each vault
    // The Ribbon vault and Opyn controller don't provide this 100% reliably
    mapping(address => IERC20) public assets;

    /// Mapping of vault balance failure thresholds
    mapping(address => uint256) public thresholds;

    /// Max number of vaults to test (to guard against block stuffing)
    uint256 public constant MAX_VAULTS = 20;

    /// Failure threshold as % of initial value (set to 10%)
    uint8 public constant INITIAL_FAILURE_THRESHOLD_PERCENT = 10;

    /// Minimum waiting period for major test updates by owner
    uint256 public constant UPDATE_WAITING_PERIOD = 172800; // 2 days

    /// Last timestamp test parameters were updated
    uint256 public lastUpdated;

    // Update-related variables
    address public pendingVault;
    uint256 public newThreshold;
    uint256 public updateCommittedTime;

    constructor() {
        protocolName = "Ribbon";

        // Initial set of vaults/assets - top vaults by TVL (90% of TVL as of 2022-11-30)
        thetaVaults.push(0x53773E034d9784153471813dacAFF53dBBB78E8c); // T-STETH-C vault
        assets[0x53773E034d9784153471813dacAFF53dBBB78E8c] = IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0); // wstETH

        thetaVaults.push(0xCc323557c71C0D1D20a1861Dc69c06C5f3cC9624); // T-USDC-P-ETH vault
        assets[0xCc323557c71C0D1D20a1861Dc69c06C5f3cC9624] = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC

        thetaVaults.push(0x25751853Eab4D0eB3652B5eB6ecB102A2789644B); // T-ETH-C vault
        assets[0x25751853Eab4D0eB3652B5eB6ecB102A2789644B] = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

        thetaVaults.push(0x65a833afDc250D9d38f8CD9bC2B1E3132dB13B2F); // T-WBTC-C vault
        assets[0x65a833afDc250D9d38f8CD9bC2B1E3132dB13B2F] = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // WBTC

        // Set initial failure thresholds (10% of vault balance at time of test deploy)
        address vault;
        uint256 numVaults = thetaVaults.length;
        for (uint256 i; i < numVaults; i++) {
            vault = thetaVaults[i];
            thresholds[vault] = (calculateAssetBalance(vault) * INITIAL_FAILURE_THRESHOLD_PERCENT) / 100;
            testedContracts.push(vault);
        }
        lastUpdated = block.timestamp;
    }

    /// @notice checks balance of Ribbon Theta V2 vaults against threshold
    /// (by default, 10% of vault balance when added to test)
    /// @return true if balance of all theta vaults is greater than thresholds
    function checkTestPasses() external view override returns (bool) {
        address vault;
        uint256 numVaults = thetaVaults.length;
        for (uint256 i; i < numVaults; i++) {
            vault = thetaVaults[i];
            if (calculateAssetBalance(vault) < thresholds[vault]) {
                return false;
            }
        }

        return true;
    }

    /// @notice computes balance of vault asset in a given Ribbon Theta Vault
    /// @param thetaVault RibbonV2 Theta Vault address
    /// @return balance of vault
    function calculateAssetBalance(address thetaVault) public view returns (uint256) {
        GammaTypes.Vault memory opynVault = controller.getVault(
            thetaVault,
            controller.getAccountVaultCounter(thetaVault)
        );

        // Note: assumes the collateral asset of interest is 1st in array
        if (
            opynVault.collateralAmounts.length > 0 &&
            opynVault.collateralAssets.length > 0 &&
            opynVault.collateralAssets[0] == address(assets[thetaVault])
        ) {
            return assets[thetaVault].balanceOf(thetaVault) + opynVault.collateralAmounts[0];
        } else {
            // in between rounds, so collateralAmounts is null array
            return assets[thetaVault].balanceOf(thetaVault);
        }
    }

    // == ADMIN FUNCTIONS == //

    /// @notice Add a Ribbon Theta Vault to test and set failure threshold
    ///         to 10% of current TVL. Can only be called by owner (Ribbon)
    /// @param vault Ribbon V2 Theta Vault address to add
    /// @param asset token address of vault asset
    function addVault(address vault, address asset) public onlyOwner {
        // Checks max vaults + valid Opyn vault for the given theta vault address
        require(thetaVaults.length < MAX_VAULTS, "Maximum number of tested vaults reached!");
        GammaTypes.Vault memory opynVault = controller.getVault(vault, controller.getAccountVaultCounter(vault));
        require(opynVault.collateralAmounts.length > 0, "Invalid vault");
        require(opynVault.collateralAssets.length > 0 && opynVault.collateralAssets[0] == asset, "assets don't match!");

        assets[vault] = IERC20(asset);
        uint256 balance = calculateAssetBalance(vault);
        require(balance > 0, "Vault has no balance!");

        thetaVaults.push(vault);
        thresholds[vault] = (balance * INITIAL_FAILURE_THRESHOLD_PERCENT) / 100;
        testedContracts.push(vault);
        lastUpdated = block.timestamp;

        emit AnteRibbonTestVaultAdded(vault, asset, thresholds[vault]);
    }

    /// @notice Propose a new vault failure threshold value and start waiting
    ///         period before update is made. Can only be called by owner (Ribbon)
    /// @param vault address of vault to reset TVL threshold for
    /// @param threshold to set (in opyn vault collateral asset with decimals)
    function commitUpdateFailureThreshold(address vault, uint256 threshold) public onlyOwner {
        require(address(assets[vault]) != address(0), "Vault not in list");
        require(pendingVault == address(0), "Another update already pending!");
        require(calculateAssetBalance(vault) >= threshold, "test would fail proposed threshold!");

        pendingVault = vault;
        newThreshold = threshold;
        updateCommittedTime = block.timestamp;
        emit AnteRibbonTestPendingUpdate(pendingVault, thresholds[pendingVault], newThreshold);
    }

    /// @notice Update test failure threshold after waiting period has passed.
    ///         Can be called by anyone, just costs gas
    function executeUpdateFailureThreshold() public {
        require(pendingVault != address(0), "No update pending!");
        require(
            block.timestamp > updateCommittedTime + UPDATE_WAITING_PERIOD,
            "Need to wait 2 days to adjust failure threshold!"
        );
        emit AnteRibbonTestUpdated(pendingVault, thresholds[pendingVault], newThreshold);
        thresholds[pendingVault] = newThreshold;

        pendingVault = address(0);
        lastUpdated = block.timestamp;
    }
}