// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IPool.sol";


interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolTHUSDDebtUpdated(uint256 _THUSDDebt);
    event ActivePoolCollateralBalanceUpdated(uint256 _collateral);
    event CollateralAddressChanged(address _newCollateralAddress);
    event CollSurplusPoolAddressChanged(address _newCollSurplusPoolAddress);

    // --- Functions ---
    function sendCollateral(address _account, uint256 _amount) external;
    function updateCollateralBalance(uint256 _amount) external;
    function collateralAddress() external view returns(address);
}