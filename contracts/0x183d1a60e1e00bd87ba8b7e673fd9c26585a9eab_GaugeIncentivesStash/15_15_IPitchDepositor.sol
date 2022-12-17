// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPitchDepositor {
    function deposit(uint256 _amount, bool _lock) external;
}

interface IFxsDepositor is IPitchDepositor {
    function lockFXS() external;
}