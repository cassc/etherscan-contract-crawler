// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);

    function getRemixCreatorRoyaltyFee()external view returns(uint256);

    function getRemixOwnerRoyaltyFee()external view returns(uint256);

}