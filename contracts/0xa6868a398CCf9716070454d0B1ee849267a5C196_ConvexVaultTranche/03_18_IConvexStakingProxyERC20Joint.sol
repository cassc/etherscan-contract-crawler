pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexStakingProxyERC20Joint.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/StakingProxyERC20Joint.sol
interface IConvexStakingProxyERC20Joint {
    function stakeLocked(uint256 _liquidity, uint256 _secs) external;
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;
    function withdrawLocked(bytes32 _kek_id) external;
    function getReward(bool _claim, address[] calldata _rewardTokenList) external;

    function stakingAddress() external view returns (address);
    function stakingToken() external view returns (address);
    function rewards() external view returns (address);
}