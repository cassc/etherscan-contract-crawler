pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/temple-frax/IStaxLPStaking.sol)

interface IStaxLPStaking {
    function stakeFor(address _for, uint256 _amount) external;
    function notifyRewardAmount(address token, uint256 reward) external;
    function rewardTokensList() external view returns (address[] memory);
}