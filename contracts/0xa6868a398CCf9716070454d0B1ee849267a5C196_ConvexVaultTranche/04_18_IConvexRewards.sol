pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexRewards.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/MultiRewards.sol
interface IConvexRewards {
    function rewardTokens(uint256 _rid) external view returns (address);
    function rewardTokenLength() external view returns(uint256);
    function active() external view returns(bool);
}