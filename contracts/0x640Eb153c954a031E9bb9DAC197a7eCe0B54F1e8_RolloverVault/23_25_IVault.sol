// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @notice Expected asset to be a valid vault asset.
/// @param token Address of the token.
error UnexpectedAsset(IERC20Upgradeable token);

/// @notice Expected transfer out asset to not be a vault asset.
/// @param token Address of the token transferred.
error UnauthorizedTransferOut(IERC20Upgradeable token);

/// @notice Expected a minimum amount of vault assets to be deployed.
error InsufficientDeployment();

/// @notice Expected the number of vault assets deployed to be under the limit.
error DeployedCountOverLimit();

/*
 *  @title IVault
 *
 *  @notice The standard interface for a generic vault as described by the "Vault Framework".
 *          http://thinking.farm/essays/2022-10-05-mechanical-finance/
 *
 *          Users deposit a "underlying" asset and mint "notes" (or vault shares).
 *          The vault "deploys" underlying asset in a rules-based fashion (through a hard-coded strategy)
 *          to "earn" income. It "recovers" deployed assets once the investment matures.
 *
 *          The vault operates through two external poke functions which off-chain keepers can execute.
 *              1) `deploy`: When executed, the vault "puts to work" the underlying assets it holds. The vault
 *                           usually returns other ERC-20 tokens which act as receipts of the deployment.
 *              2) `recover`: When executed, the vault turns in the receipts and retrieves the underlying asset and
 *                            usually collects some yield for this work.
 *
 *          The rules of the deployment and recovery are specific to the vault strategy.
 *
 *          At any time the vault will hold multiple ERC20 tokens, together referred to as the vault's "assets".
 *          They can be a combination of the underlying asset, the earned asset and the deployed assets (receipts).
 *
 *          On redemption users burn their "notes" to receive a proportional slice of all the vault's assets.
 *
 */

interface IVault {
    /// @notice Recovers deployed funds and redeploys them.
    function recoverAndRedeploy() external;

    /// @notice Deploys deposited funds.
    function deploy() external;

    /// @notice Recovers deployed funds.
    function recover() external;

    /// @notice Recovers a given deployed asset.
    /// @param token The ERC-20 token address of the deployed asset.
    function recover(IERC20Upgradeable token) external;

    /// @notice Deposits the underlying asset from {msg.sender} into the vault and mints notes.
    /// @param amount The amount tokens to be deposited into the vault.
    /// @return The amount of notes.
    function deposit(uint256 amount) external returns (uint256);

    struct TokenAmount {
        /// @notice The asset token redeemed.
        IERC20Upgradeable token;
        /// @notice The amount redeemed.
        uint256 amount;
    }

    /// @notice Burns notes and sends a proportional share of vault's assets back to {msg.sender}.
    /// @param notes The amount of notes to be burnt.
    /// @return The list of asset tokens and amounts redeemed.
    function redeem(uint256 notes) external returns (TokenAmount[] memory);

    /// @return The total value of assets currently held by the vault, denominated in a standard unit of account.
    function getTVL() external returns (uint256);

    /// @param token The address of the asset ERC-20 token held by the vault.
    /// @return The vault's asset token value, denominated in a standard unit of account.
    function getVaultAssetValue(IERC20Upgradeable token) external returns (uint256);

    /// @notice The ERC20 token that can be deposited into this vault.
    function underlying() external view returns (IERC20Upgradeable);

    /// @param token The address of the asset ERC-20 token held by the vault.
    /// @return The vault's asset token balance.
    function vaultAssetBalance(IERC20Upgradeable token) external view returns (uint256);

    /// @return Total count of deployed asset tokens held by the vault.
    function deployedCount() external view returns (uint256);

    /// @param i The index of a token.
    /// @return The token address from the deployed asset token list by index.
    function deployedAt(uint256 i) external view returns (IERC20Upgradeable);

    /// @return Total count of earned income tokens held by the vault.
    function earnedCount() external view returns (uint256);

    /// @param i The index of a token.
    /// @return The token address from the earned income token list by index.
    function earnedAt(uint256 i) external view returns (IERC20Upgradeable);

    /// @param token The address of a token to check.
    /// @return If the given token is held by the vault.
    function isVaultAsset(IERC20Upgradeable token) external view returns (bool);
}