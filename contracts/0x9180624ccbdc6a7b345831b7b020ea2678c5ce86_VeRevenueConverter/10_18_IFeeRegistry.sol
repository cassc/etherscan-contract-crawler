// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFeeRegistry {
    function feeAddress() external view returns (address);

    function unmanagedLPFee() external view returns (uint256);

    function FEE_DENOMINATOR() external view returns (uint256);

    function veRevenueFee() external view returns (uint256);
}