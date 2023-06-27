// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IIncentivesController {
    /// @notice Point in time where distribution rewards end
    function DISTRIBUTION_END() external view returns (uint256);

    /// @notice address to `AssetData`
    function assets(address) external view returns (uint128, uint128, uint256);

    /// @dev Returns the total of rewards of an user, already accrued + not yet accrued
    /// @param _assets The assets to incentivize
    /// @param _user The address of the user
    /// @return The rewards
    function getRewardsBalance(IScaledBalanceToken[] calldata _assets, address _user)
        external
        view
        returns (uint256);

    /// @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
    /// @param _assets The assets to incentivize
    /// @param _amount Amount of rewards to claim
    /// @return Rewards claimed
    function claimRewards(IScaledBalanceToken[] calldata _assets, uint256 _amount)
        external
        returns (uint256);

    /// @dev returns the unclaimed rewards of the user
    /// @param _user the address of the user
    /// @return the unclaimed user rewards
    function getUserUnclaimedRewards(address _user) external view returns (uint256);

    /// @dev Returns the data of an user on a distribution
    /// @param _user Address of the user
    /// @param _asset The address of the reference asset of the distribution
    /// @return The new index
    function getUserAssetData(address _user, address _asset) external view returns (uint256);
}

interface IScaledBalanceToken {
    /// @dev Returns the scaled balance of the user and the scaled total supply.
    /// @param user The address of the user
    /// @return The scaled balance of the user
    /// @return The scaled balance and the scaled total supply
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /// @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
    /// @return The scaled total supply
    function scaledTotalSupply() external view returns (uint256);
}