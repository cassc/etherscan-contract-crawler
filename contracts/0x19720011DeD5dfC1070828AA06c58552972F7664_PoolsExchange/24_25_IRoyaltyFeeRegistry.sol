// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function updateRoyaltyInfoForNFTCollection(
        address collection,
        uint256 tokenId,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );

    function royaltyFeeInfoNFTCollection(address collection, uint256 tokenId)
        external
        view
        returns (
            address,
            address,
            uint256
        );

    function royaltyInfo(
        address collection,
        uint256 amount,
        uint256 tokenId
    ) external view returns (address, uint256);
}