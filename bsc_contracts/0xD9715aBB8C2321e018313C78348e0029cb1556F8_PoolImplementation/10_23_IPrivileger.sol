// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPrivileger {

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function isQualifiedLiquidator(address liquidator) external view returns (bool);

}