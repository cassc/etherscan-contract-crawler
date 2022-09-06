// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CreatorFeeEngineInterface {
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}