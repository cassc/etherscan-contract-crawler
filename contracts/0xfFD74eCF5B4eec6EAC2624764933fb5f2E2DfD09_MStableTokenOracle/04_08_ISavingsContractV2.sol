// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISavingsContractV2 {
    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2
}