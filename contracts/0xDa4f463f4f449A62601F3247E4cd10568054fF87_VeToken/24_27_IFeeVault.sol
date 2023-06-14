// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IFeeVault{
    function distribute(address _user, uint256 _amount) external;
    function generationRateETH() external view returns(uint256);
}