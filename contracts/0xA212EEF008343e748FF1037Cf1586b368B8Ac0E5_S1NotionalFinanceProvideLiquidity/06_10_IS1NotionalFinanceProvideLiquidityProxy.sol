// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/INotionalFinance.sol";


interface IS1NotionalFinanceProvideLiquidityProxy {
    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _deposit, INotionalFinance.DepositActionType actionType) external payable;
    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) external returns(uint256);
    function claimToDepositor(address _depositor) external returns(uint256);
    function claimToDeployer() external returns(uint256);
}