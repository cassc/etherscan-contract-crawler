// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title   Collects reward tokens from vaults, swaps them and donated the purchased token back to the vaults.
 *          Supports asynchronous and synchronous swaps.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 */
interface ILiquidatorV2 {
    function collectRewards(address[] memory vaults)
        external
        returns (
            address[][] memory rewardTokens,
            uint256[][] memory rewards,
            address[][] memory purchaseTokens
        );

    function initiateSwap(
        address rewardToken,
        address assetToken,
        bytes memory data
    ) external returns (uint256 batch, uint256 rewards);

    function swap(
        address rewardToken,
        address assetToken,
        uint256 minAssets,
        bytes memory data
    )
        external
        returns (
            uint256 batch,
            uint256 rewards,
            uint256 assets
        );

    function initiateSwaps(
        address[] memory rewardTokens,
        address[] memory assetTokens,
        bytes[] memory datas
    ) external returns (uint256[] memory batchs, uint256[] memory rewards);

    function settleSwaps(
        address[] memory rewardTokens,
        address[] memory assetTokens,
        uint256[] memory assets,
        bytes[] memory datas
    ) external returns (uint256[] memory batchs, uint256[] memory rewards);
}