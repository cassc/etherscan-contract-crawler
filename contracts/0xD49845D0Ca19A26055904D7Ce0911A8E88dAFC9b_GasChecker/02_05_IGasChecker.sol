// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IGasChecker {

    function gasOracle() external view returns(address);
    function gasTolerance() external view returns(uint256);
    function checkGas() external view returns(int256);
    function isGasAcceptable() external view returns(bool);

    function setGasTolerance(uint256 _gasTolerance) external;

    event DeployGasChecker(
        address indexed sender,
        address gasOracle, 
        uint256 gasTolerance
    );

    event SetGasTolerance(
        address indexed sender, 
        uint256 gasTolerance
    );
}