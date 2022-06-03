// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./IERC20.sol";
import "./IInterestRateModel.sol";

interface IXToken is IERC20 {

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint(uint256 amount) external payable;
    function redeem(uint256 redeemTokens) external;
    function redeemUnderlying(uint256 redeemAmounts) external;

    function borrow(uint256 orderId, address payable borrower, uint256 borrowAmount) external;
    function repayBorrow(uint256 orderId, address borrower, uint256 repayAmount) external payable;
    function liquidateBorrow(uint256 orderId, address borrower) external payable;

    function orderLiquidated(uint256 orderId) external view returns(bool, address, uint256); 

    function accrueInterest() external;

    function borrowBalanceCurrent(uint256 orderId) external returns (uint256);
    function borrowBalanceStored(uint256 orderId) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns(address);
    function totalBorrows() external view returns(uint256);
    function totalCash() external view returns (uint256);
    function totalReserves() external view returns (uint256);

    /**admin function **/
    function setPendingAdmin(address payable newPendingAdmin) external;
    function acceptAdmin() external;
    function setReserveFactor(uint256 newReserveFactor) external;
    function reduceReserves(uint256 reduceAmount) external;
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;
    function setTransferEthGasCost(uint256 _transferEthGasCost) external;

    /**event */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(uint256 orderId, address borrower, uint256 borrowAmount, uint256 orderBorrows, uint256 totalBorrows);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    
}