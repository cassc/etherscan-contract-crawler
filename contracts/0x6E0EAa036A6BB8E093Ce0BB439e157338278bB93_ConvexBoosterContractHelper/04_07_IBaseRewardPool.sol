// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../../../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IBaseRewardPool {
    function rewardToken() external view returns (IERC20);

    function rewards(address) external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function getReward() external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 i) external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);

    function withdrawAllAndUnwrap(bool claim) external;
}