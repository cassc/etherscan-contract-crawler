// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IStrategy {
     function cloneConvex3CrvRewards(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) external returns (address newStrategy);

    function setHealthCheck(address) external;
}