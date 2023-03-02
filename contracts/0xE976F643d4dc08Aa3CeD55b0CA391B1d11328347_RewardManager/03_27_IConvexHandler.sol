// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IConvexHandler {
    function deposit(address _curvePool, uint256 _amount) external;

    function claimBatchEarnings(address[] memory _curvePools, address _conicPool) external;

    function getRewardPool(address _curvePool) external view returns (address);

    function getCrvEarned(address _account, address _curvePool) external view returns (uint256);

    function getCrvEarnedBatch(address _account, address[] memory _curvePools)
        external
        view
        returns (uint256);

    function computeClaimableConvex(uint256 crvAmount) external view returns (uint256);
}