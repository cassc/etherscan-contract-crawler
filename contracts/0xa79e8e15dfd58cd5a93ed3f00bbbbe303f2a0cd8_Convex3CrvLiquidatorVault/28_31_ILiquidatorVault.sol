// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title   Interface that the Liquidator uses to interact with vaults.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 */
interface ILiquidatorVault {
    /**
     * @notice Used by the liquidator to collect rewards from the vault's underlying platforms
     * or vaults into the vault contract.
     * The liquidator will transfer the collected rewards from the vault to the liquidator separately
     * to the `collectRewards` call.
     *
     * @param rewardTokens Array of reward tokens that were collected.
     * @param rewards The amount of reward tokens that were collected.
     * @param purchaseTokens The token to purchase for each of the rewards.
     */
    function collectRewards()
        external
        returns (
            address[] memory rewardTokens,
            uint256[] memory rewards,
            address[] memory purchaseTokens
        );

    /**
     * @notice Adds assets to a vault which decides what to do with the extra tokens.
     * If the tokens are the vault's asset, the simplest is for the vault to just add
     * to the other assets without minting any shares.
     * This has the effect of increasing the vault's assets per share.
     * This can be a problem if there is a relatively large amount of assets being donated as it can be sandwich attacked.
     * The attacker can mint a large amount of shares before the donation and then redeem them afterwards taking most of the donated assets.
     * This can be avoided by streaming the increase of assets per share over time. For example,
     * minting new shares and then burning them over a period of time. eg one day.
     *
     * @param token The address of the tokens being donated.
     * @param amount The amount of tokens being donated.
     */
    function donate(address token, uint256 amount) external;

    /**
     * @notice Returns all reward token addresses added to the vault.
     */
    function rewardTokens() external view returns (address[] memory rewardTokens);

    /**
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     * @param rewardToken The address of the reward token.
     * @return token The address of the tokens being donated.
     */
    function donateToken(address rewardToken) external view returns (address token);
}