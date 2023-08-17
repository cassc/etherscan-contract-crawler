// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IQWAFactory {
    function WETH() external view returns (address);
    function QWN() external view returns (address);
    function sQWN() external view returns (address);
    function QWNStaking() external view returns (address);
    function feeAddress() external view returns (address);
    function feeDiscount(address _user) external view returns (bool);
}