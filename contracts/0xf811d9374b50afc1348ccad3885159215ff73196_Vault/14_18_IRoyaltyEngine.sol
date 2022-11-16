// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRoyaltyEngine {
    function getRoyaltyView(
        address collection,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address[] memory recipients, uint256[] memory amounts);
}