// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RoyaltyFeeTypes} from "../libraries/RoyaltyFeeTypes.sol";

interface IRoyaltyFeeRegistryV2 {
    function updateRoyaltyInfoPartsForCollection(
        address collection,
        address setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory feeInfoParts
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function updateMaxNumRecipients(uint8 _maxNumRecipients) external;

    function royaltyAmountParts(address _collection, uint256 _amount)
        external
        view
        returns (RoyaltyFeeTypes.FeeAmountPart[] memory);

    function royaltyFeeInfoPartsCollectionSetter(address collection)
        external
        view
        returns (address);
}