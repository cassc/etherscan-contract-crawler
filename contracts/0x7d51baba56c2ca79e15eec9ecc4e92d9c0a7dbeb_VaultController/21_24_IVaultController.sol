// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { VaultInitParams, VaultFees, IERC4626, IERC20 } from "./IVault.sol";
import { VaultMetadata } from "./IVaultRegistry.sol";
import { IDeploymentController } from "./IDeploymentController.sol";

struct DeploymentArgs {
  /// @Notice templateId
  bytes32 id;
  /// @Notice encoded init params
  bytes data;
}

interface IVaultController {
  function deployVault(
    VaultInitParams memory vaultData,
    DeploymentArgs memory adapterData,
    DeploymentArgs memory strategyData,
    bool deployStaking,
    bytes memory rewardsData,
    VaultMetadata memory metadata,
    uint256 initialDeposit
  ) external returns (address);

  function deployAdapter(
    IERC20 asset,
    DeploymentArgs memory adapterData,
    DeploymentArgs memory strategyData,
    uint256 initialDeposit
  ) external returns (address);

  function deployStaking(IERC20 asset) external returns (address);

  function proposeVaultAdapters(address[] calldata vaults, IERC4626[] calldata newAdapter) external;

  function changeVaultAdapters(address[] calldata vaults) external;

  function proposeVaultFees(address[] calldata vaults, VaultFees[] calldata newFees) external;

  function changeVaultFees(address[] calldata vaults) external;

  function setVaultQuitPeriods(address[] calldata vaults, uint256[] calldata quitPeriods) external;

  function setVaultFeeRecipients(address[] calldata vaults, address[] calldata feeRecipients) external;

  function registerVaults(address[] calldata vaults, VaultMetadata[] calldata metadata) external;

  function addClones(address[] calldata clones) external;

  function toggleEndorsements(address[] calldata targets) external;

  function toggleRejections(address[] calldata targets) external;

  function addStakingRewardsTokens(address[] calldata vaults, bytes[] calldata rewardsTokenData) external;

  function changeStakingRewardsSpeeds(
    address[] calldata vaults,
    IERC20[] calldata rewardTokens,
    uint160[] calldata rewardsSpeeds
  ) external;

  function fundStakingRewards(
    address[] calldata vaults,
    IERC20[] calldata rewardTokens,
    uint256[] calldata amounts
  ) external;

  function setEscrowTokenFees(IERC20[] calldata tokens, uint256[] calldata fees) external;

  function addTemplateCategories(bytes32[] calldata templateCategories) external;

  function toggleTemplateEndorsements(bytes32[] calldata templateCategories, bytes32[] calldata templateIds) external;

  function pauseAdapters(address[] calldata vaults) external;

  function pauseVaults(address[] calldata vaults) external;

  function unpauseAdapters(address[] calldata vaults) external;

  function unpauseVaults(address[] calldata vaults) external;

  function nominateNewAdminProxyOwner(address newOwner) external;

  function acceptAdminProxyOwnership() external;

  function setPerformanceFee(uint256 newFee) external;

  function setAdapterPerformanceFees(address[] calldata adapters) external;

  function performanceFee() external view returns (uint256);

  function setHarvestCooldown(uint256 newCooldown) external;

  function setAdapterHarvestCooldowns(address[] calldata adapters) external;

  function harvestCooldown() external view returns (uint256);

  function setDeploymentController(IDeploymentController _deploymentController) external;

  function setActiveTemplateId(bytes32 templateCategory, bytes32 templateId) external;

  function activeTemplateId(bytes32 templateCategory) external view returns (bytes32);
}