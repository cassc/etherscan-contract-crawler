// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyNFT {
    function getCreator(uint256 token_id) external returns (address);
    function getRoyaltyInfo(uint256 token_id) external view returns (address, uint256, bool);
    function updateFirstSale(uint256 token_id) external;
}