// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IFeeManager {
    function fetchFees() external payable returns (uint256);
    function fetchExactFees(uint256 _feeAmount) external payable returns (uint256);

    function getFactoryFeeInfo(address _factoryAddress)
        external
        view
        returns (uint256, address);
}