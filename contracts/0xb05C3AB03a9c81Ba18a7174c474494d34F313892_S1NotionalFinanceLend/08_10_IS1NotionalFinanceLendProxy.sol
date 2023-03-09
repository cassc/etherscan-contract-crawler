// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/INotionalFinance.sol";


interface IS1NotionalFinanceLendProxy {
    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _deposit, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external payable;
    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) external returns(uint256);
    function withdrawBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) external returns(uint256);
    function rollToNewMaturity(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, uint8 _ethMarketIndex, uint32 _maxImpliedRate, uint256 _maturity, uint32 _minLendRate) external;
    function lendMaturedBalance(uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external;
}