// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// Interface for ICreatorNFT
interface ICreatorNFT {
    function getRoyaltyFeePercentage() external view returns (uint royalty);
    function owner() external view returns (address);
}