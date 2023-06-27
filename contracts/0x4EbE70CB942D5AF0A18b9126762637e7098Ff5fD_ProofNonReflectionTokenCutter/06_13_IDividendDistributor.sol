// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function setMinPeriod(uint256 _minPeriod) external;

    function setMinDistribution(uint256 _minDistribution) external;

    function rewardTokenAddress() external view returns(address);
}