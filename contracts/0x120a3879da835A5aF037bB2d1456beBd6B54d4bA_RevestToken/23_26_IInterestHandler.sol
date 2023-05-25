// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IInterestHandler  {

    function registerDeposit(uint fnftId) external;

    function getPrincipal(uint fnftId) external view returns (uint);

    function getInterest(uint fnftId) external view returns (uint);

    function getAmountToWithdraw(uint fnftId) external view returns (uint);

    function getUnderlyingToken(uint fnftId) external view returns (address);

    function getUnderlyingValue(uint fnftId) external view returns (uint);

    //These methods exist for external operations
    function getPrincipalDetail(uint historic, uint amount, address asset) external view returns (uint);

    function getInterestDetail(uint historic, uint amount, address asset) external view returns (uint);

    function getUnderlyingTokenDetail(address asset) external view returns (address);

    function getInterestRate(address asset) external view returns (uint);

}