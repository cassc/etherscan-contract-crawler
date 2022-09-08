// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISYLVestingWallet {
    function beneficiary() external view returns (address);
    function setBeneficiary(address beneficiaryAddress) external;
    function start() external view returns (uint256);
    function duration() external view returns (uint256);
    function released() external view returns (uint256);
    function release() external;
    function vestedAmount(uint64 timestamp) external view returns (uint256);
}