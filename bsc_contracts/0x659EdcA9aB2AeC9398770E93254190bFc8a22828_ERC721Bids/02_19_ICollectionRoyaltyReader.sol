// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface ICollectionRoyaltyReader {
    struct RoyaltyAmount {
        address receiver;
        uint256 royaltyAmount;
    }

    /**
     * @dev Get collection royalty receiver list
     * @param collectionAddress to read royalty receiver
     * @return list of royalty receivers and their shares
     */
    function royaltyInfo(
        address collectionAddress,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (RoyaltyAmount[] memory);
}