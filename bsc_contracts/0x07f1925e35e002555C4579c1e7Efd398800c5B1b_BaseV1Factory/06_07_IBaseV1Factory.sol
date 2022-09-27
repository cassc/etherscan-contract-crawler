/**
 * @title interface V1 Factory
 * @dev IBaseV1Factory.sol contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: Business Source License 1.1
 *
 **/

pragma solidity = 0.8.11;

interface IBaseV1Factory {
    function protocolAddresses(address _pair) external returns (address);
    function usdfiMaker() external returns (address);
    function feeAmountOwner() external returns (address);
    function admin() external returns (address);
    function owner() external returns (address);
    function baseStableFee() external returns (uint256);
    function baseVariableFee() external returns (uint256);
}
