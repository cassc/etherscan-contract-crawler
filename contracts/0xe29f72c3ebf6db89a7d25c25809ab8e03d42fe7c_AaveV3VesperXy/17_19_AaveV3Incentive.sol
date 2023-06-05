// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "../../../interfaces/aave/IAave.sol";

/// @title This contract provide core operations for Aave v3
library AaveV3Incentive {
    /**
     * @notice Claim rewards from Aave incentive controller
     */
    function _claimRewards(
        address _aToken
    ) internal returns (address[] memory rewardsList, uint256[] memory claimedAmounts) {
        // Some aTokens may have no incentive controller method/variable. Better use try catch
        try AToken(_aToken).getIncentivesController() returns (address _aaveIncentivesController) {
            address[] memory assets = new address[](1);
            assets[0] = address(_aToken);
            return AaveIncentivesController(_aaveIncentivesController).claimAllRewards(assets, address(this));
            //solhint-disable no-empty-blocks
        } catch {}
    }
}