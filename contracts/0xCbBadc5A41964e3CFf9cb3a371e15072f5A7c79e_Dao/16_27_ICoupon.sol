// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICoupon {
    function toggleJuicing(
        uint256[] calldata tokenIds,
        bool juicing,
        uint256 taskId
    ) external;

    function ownerOf(uint256[] calldata tokenIds) external view returns (address);
    function getCouponsValue(uint256[] calldata tokenIds) external view returns (uint256);
    function getCouponPurchaseValue(uint256 _tokenID) external view returns (uint256);
}