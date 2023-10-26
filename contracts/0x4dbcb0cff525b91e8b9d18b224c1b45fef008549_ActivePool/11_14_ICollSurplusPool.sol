// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface ICollSurplusPool {

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralAddressChanged(address _newCollateralAddress);

    event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
    event CollateralSent(address _to, uint256 _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _collateralAddress
    ) external;

    function getCollateralBalance() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint256 _amount) external;

    function claimColl(address _account) external;

    function updateCollateralBalance(uint256 _amount) external;
    
    function collateralAddress() external view returns(address);
}