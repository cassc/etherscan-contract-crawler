// "SPDX-License-Identifier: MIT"

pragma solidity 0.8.4;

interface IFeeManager
{
    function calculateFee(address _token, uint256 _amount) external view returns (uint256);
    function getFeeCollector() external view returns (address);
}