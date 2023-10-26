// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Common interface for the Pools.
interface IPool {

    // --- Events ---

    event CollateralBalanceUpdated(uint256 _newBalance);
    event THUSDBalanceUpdated(uint256 _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event CollateralSent(address _to, uint256 _amount);

    // --- Functions ---

    function getCollateralBalance() external view returns (uint);

    function getTHUSDDebt() external view returns (uint);

    function increaseTHUSDDebt(uint256 _amount) external;

    function decreaseTHUSDDebt(uint256 _amount) external;
}