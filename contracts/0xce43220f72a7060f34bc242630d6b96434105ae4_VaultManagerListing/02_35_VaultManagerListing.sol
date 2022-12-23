// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { IBorrowStakerCheckpoint } from "../interfaces/IBorrowStaker.sol";
import "borrow/vaultManager/VaultManager.sol";

/// @title VaultManagerListing
/// @author Angle Labs, Inc.
/// @notice Provides an additional viewer to `VaultManager` to get the full collateral deposited
/// by an owner
/// @dev This implementation is built to interact with `collateral` that are in fact `staker` contracts wrapping
/// another collateral asset.
///
/// @dev Some things are worth noting regarding transfers and updates in the `totalBalanceOf` for such `collateral`.
/// When adding or removing collateral to/from a vault, the `totalBalanceOf` of an address is updated, even if the asset
/// has not been transferred yet, meaning there can be two checkpoints for in fact a single transfer.
///
/// @dev Adding collateral to a vault increases the total balance of the `sender`. But after the vault collateral increase,
/// since the `sender` still owns the `collateral`, there is a double count in the total balance. This is not a
/// problem as the `sender` was already checkpointed in the `_addCollateral`.
///
/// @dev In the case of a `burn` or `removeCollateral` action, there is a first checkpoint with the correct balances,
/// and then a second one when the vault transfers the `collateral` with a deflated balance in this case.
///
/// @dev Conclusion is that the logic on which this contract is built is working as expected as long as no rewards
/// are distributed within a same tx from the staking contract. Most protocols already follow this hypothesis,
/// but for those who don't, this vault implementation doesn't work
///
/// @dev Note that it is a weaker assumption than what is done in the `staker` contract which supposes that no rewards
/// can be distributed to the same address within a block
contract VaultManagerListing is VaultManager {
    using SafeERC20 for IERC20;
    using Address for address;

    // ================= INTERNAL UTILITY STATE-MODIFYING FUNCTIONS ================

    /// @inheritdoc VaultManagerERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 vaultID
    ) internal override {
        // If the transfer is between 2 addresses we need to checkpoint both of them.
        // If it is a burn we also need to checkpoint as the burn didn't trigger yet a change in collateral amount
        if (from != address(0)) {
            uint256 collateralAmount = vaultData[vaultID].collateralAmount;
            _checkpointWrapper(from, collateralAmount, false);
            if (to != address(0)) _checkpointWrapper(to, collateralAmount, true);
        }
    }

    /// @inheritdoc VaultManager
    /// @dev Checkpoints the `collateral` of the contract after an update of the `collateralAmount` of vaultID
    function _checkpointCollateral(
        uint256 vaultID,
        uint256 amount,
        bool add
    ) internal override {
        _checkpointWrapper(_ownerOf(vaultID), amount, add);
    }

    /// @notice Checkpoint rewards for `user` in the `staker` contract
    /// @param user Address for which the balance should be updated
    /// @param amount Amount of collateral added / removed from the vault
    /// @param add Whether the collateral was added or removed from the vault
    /// @dev Whenever there is an internal transfer or a transfer from the `vaultManager`,
    /// we need to update the rewards to correctly track everyone's claim
    function _checkpointWrapper(
        address user,
        uint256 amount,
        bool add
    ) internal {
        IBorrowStakerCheckpoint(address(collateral)).checkpointFromVaultManager(user, amount, add);
    }
}