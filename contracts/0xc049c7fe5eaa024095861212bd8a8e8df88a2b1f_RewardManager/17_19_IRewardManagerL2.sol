// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

// interfaces
import "./IFarmingRange.sol";

interface IRewardManagerL2 {
    /**
     * @notice used to resetAllowance with farming contract to take rewards
     * @param _campaignId campaign id
     */
    function resetAllowance(uint256 _campaignId) external;

    /**
     * @notice used to get the farming contract address
     * @return farming contract address (or FarmingRange contract type in Solidity)
     */
    function farming() external view returns (IFarmingRange);
}