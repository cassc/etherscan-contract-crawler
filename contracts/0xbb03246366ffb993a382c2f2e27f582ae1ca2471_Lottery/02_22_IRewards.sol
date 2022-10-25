//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewards {
    /**
     * Points earned by the user.
     */
    function burnUserPoints(address account, uint256 amount)
        external
        returns (uint256);

    function availablePoints(address _user) external view returns (uint256);

    function totalPointsUsed(address _user) external view returns (uint256);

    function totalPointsEarned(address _user) external view returns (uint256);

    function refundPoints(address _account, uint256 _points) external;

    function claimPoints(address _account, uint256 _points) external;
}