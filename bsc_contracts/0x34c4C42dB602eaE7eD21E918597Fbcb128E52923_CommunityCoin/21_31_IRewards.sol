// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IHook.sol";
interface IRewards is IHook {

    function initialize(
        address sellingToken,
        uint256[] memory timestamps,
        uint256[] memory prices,
        uint256[] memory thresholds,
        uint256[] memory bonuses
    ) external;

    function onClaim(address account) external;

    function onUnstake(address instance, address account, uint64 duration, uint256 amount, uint64 rewardsFraction) external;
}