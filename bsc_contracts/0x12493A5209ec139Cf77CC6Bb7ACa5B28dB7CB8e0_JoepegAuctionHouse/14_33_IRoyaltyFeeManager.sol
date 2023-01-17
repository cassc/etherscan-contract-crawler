// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RoyaltyFeeTypes} from "../libraries/RoyaltyFeeTypes.sol";

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);

    function calculateRoyaltyFeeAmountParts(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (RoyaltyFeeTypes.FeeAmountPart[] memory);
}