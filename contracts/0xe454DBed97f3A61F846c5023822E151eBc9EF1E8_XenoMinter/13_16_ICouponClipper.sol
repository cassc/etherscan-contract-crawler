// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

struct Signature {
  bytes32 r;
  bytes32 s;
  uint8 v;
}

struct Coupon {
    mapping(address => uint256) claimerCount;
}

interface ICouponClipper is IERC165 {
    function getCouponUsage(uint16 couponId, address claimer) external view returns (uint256);

    function decodeCoupon(bytes memory coupon) 
    external 
    pure 
    returns (uint16 couponId, address allowedClaimer, uint16 maxCount, uint256 value, uint256 expiry);

    function getCouponIssuer() external view returns (address);

    function clipCoupon(address claimer, uint256 count, Signature memory signature, bytes memory coupon) external returns (uint256);
}