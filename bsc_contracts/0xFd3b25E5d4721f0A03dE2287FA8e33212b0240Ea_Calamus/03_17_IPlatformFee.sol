// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Types.sol";
pragma abicoder v2;

interface IPlatformFee {
    event WithdrawFee(address tokenAddress, address to, uint256 amount);
    event SetRateFee(uint32 rateFee);
    event AddWithdrawFeeAddress(address allowAddress, uint32 percentage);
    event RemoveWithdrawFeeAddress(address allowAddress);
    function setRateFee(uint32 rateFee) external;
    function getContractFee(address tokenAddress) external view returns(uint256);
    function withdrawFee(address to, address tokenAddress, uint256 amount) external returns (bool);
    function addWithdrawFeeAddress(address allowAddress, uint32 percentage) external ;
    function removeWithdrawFeeAddress(address allowAddress) external returns (bool) ;
    function getWithdrawFeeAddresses() external view returns(Types.WithdrawFeeAddress[] memory);
    function isAllowWithdrawingFee(address allowAddress) external view returns (bool);
}