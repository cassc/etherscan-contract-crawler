// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IPool.sol";


interface IDefaultPool is IPool {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolTHUSDDebtUpdated(uint256 _THUSDDebt);
    event DefaultPoolCollateralBalanceUpdated(uint256 _collateral);
    event CollateralAddressChanged(address _newCollateralAddress);

    // --- Functions ---
    function sendCollateralToActivePool(uint256 _amount) external;
    function updateCollateralBalance(uint256 _amount) external;
    function collateralAddress() external view returns(address);
}