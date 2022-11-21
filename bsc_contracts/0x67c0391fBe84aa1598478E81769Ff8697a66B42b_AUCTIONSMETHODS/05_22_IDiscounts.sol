// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IDiscounts {
    function addDiscount(uint8 _tokenType, address _tokenContract, uint8 _discount, uint256[] memory _tokenIds) external;
    function getDiscountTokenId(uint256 _discountId, uint256 tokenIdIndex) external view returns(uint256);
    function getDiscountTokenIds(uint256 _discountId) external view returns(uint256[] memory);
    function editDiscount(uint256 _discountId, address _tokenContract, uint8 _discount, uint256[] calldata _tokenIds, uint8 _tokenType) external;
    function calculateDiscount(address requester) external view returns(uint256);
}