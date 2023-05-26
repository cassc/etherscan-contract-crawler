// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function depositNative() external payable;
    function depositToken(address from, uint256 amount) external;
    function process(uint256 gas) external;
    function inSwap() external view returns (bool);
}