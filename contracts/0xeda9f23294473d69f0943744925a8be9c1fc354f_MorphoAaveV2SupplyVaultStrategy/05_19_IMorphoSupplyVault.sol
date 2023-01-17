// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.10;

import "../IERC4626.sol";

interface IMorphoSupplyVault is IERC4626 {
    /// Morpho-Compound Supply Vault

    /// @notice Claims rewards on behalf of `_user`.
    /// @param _user The address of the user to claim rewards for.
    /// @return rewardsAmount The amount of rewards claimed.
    function claimRewards(address _user) external returns (uint256 rewardsAmount);
}