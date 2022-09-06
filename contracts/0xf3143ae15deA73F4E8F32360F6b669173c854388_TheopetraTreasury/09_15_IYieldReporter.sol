// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IYieldReporter {
    event ReportYield(uint256 indexed id, int256 yield);

    function lastYield() external view returns (int256);

    function currentYield() external view returns (int256);

    function getYieldById(uint256 id) external view returns (int256);

    function reportYield(int256 _amount) external returns (uint256);
}