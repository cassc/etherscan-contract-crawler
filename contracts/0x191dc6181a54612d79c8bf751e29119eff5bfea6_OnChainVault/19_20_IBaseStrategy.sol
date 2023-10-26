// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IBaseStrategy {
    function adjustPosition(uint256 _debtOutstanding) external;

    function migrate(address _newStrategy) external;

    function withdraw(uint256 amount) external returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function delegatedAssets() external view returns (uint256);
}