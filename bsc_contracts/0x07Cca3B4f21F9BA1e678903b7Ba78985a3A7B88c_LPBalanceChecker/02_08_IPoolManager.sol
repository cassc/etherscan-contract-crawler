// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPoolManager {
    function allNewPools() external view returns (address[] memory);

    function allLegacyPools() external view returns (address[] memory);

    function viewTotalGovernanceHoldings(address userAddress)
        external
        view
        returns (uint256);

    function getActivePoolCount() external view returns (uint256);

    function allActivePools() external view returns (address[] memory);
}