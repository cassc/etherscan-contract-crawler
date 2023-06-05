// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;
    function royaltyInfo(address collection, uint256 amount) external view returns (address, uint256);
    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
    function getRemixCreatorRoyaltyFee() external view returns (uint256);
    function getRemixOwnerRoyaltyFee() external view returns (uint256);
    function updateRoyaltyRemixCreator(uint256 _royalty) external;
    function updateRoyaltyRemixOwner(uint256 _royalty) external ;
}