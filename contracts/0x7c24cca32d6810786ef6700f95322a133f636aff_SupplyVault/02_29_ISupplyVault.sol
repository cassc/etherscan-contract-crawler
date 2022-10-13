// SPDX-License-Identifier: GNU AGPLv3
pragma solidity >=0.8.0;

import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

interface ISupplyVault is IERC4626Upgradeable {
    function rewardsIndex() external view returns (uint256);

    function userRewards(address _user) external view returns (uint128, uint128);

    function claimRewards(address _user) external returns (uint256 rewardsAmount);
}