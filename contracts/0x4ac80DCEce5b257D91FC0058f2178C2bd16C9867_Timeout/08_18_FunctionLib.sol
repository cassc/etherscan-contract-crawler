// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { DataLibrarry } from "./DataLibrarry.sol";
import { ITimeout } from "../ITimeout.sol";

library FunctionLib {
  /**
  * @notice verifyCoupon verify the coupon
  * @dev hash the info and check if valid signature
  */
  function verifyCoupon(
    address signer,
    DataLibrarry.Coupon memory coupon,
    DataLibrarry.CouponType couponType,
    DataLibrarry.CouponTypeCount memory couponTypeCount
  )
    internal
    view
  {
    bytes32 digest = getMessageHash(
      couponType,
      couponTypeCount
    );
    if (_isVerifiedCoupon(digest, coupon) != signer)
      revert ITimeout.InvalidCoupon();
  }

  function getMessageHash(
    DataLibrarry.CouponType couponType,
    DataLibrarry.CouponTypeCount memory couponTypeCount
  )
    internal
    view
    returns(bytes32)
  {
    return keccak256(
      abi.encode(
        couponType,
        couponTypeCount.BasicCount,
        couponTypeCount.UltrarareCount,
        couponTypeCount.LegendaireCount,
        couponTypeCount.eggCount,
        msg.sender
      )
    );
  }

  function getMessageHashForAddress(
    DataLibrarry.CouponType couponType,
    DataLibrarry.CouponTypeCount memory couponTypeCount,
    address addressToEncode
  )
    internal
    pure
    returns(bytes32)
  {
    return keccak256(
      abi.encode(
        couponType,
        couponTypeCount.BasicCount,
        couponTypeCount.UltrarareCount,
        couponTypeCount.LegendaireCount,
        couponTypeCount.eggCount,
        addressToEncode
      )
    );
  }

  /**
  * @notice verifyCouponForClaim verify the coupon for claim
  * @dev hash the info and check if valid signature
  */
  function verifyCouponForClaim(
    address signer,
    DataLibrarry.Coupon memory coupon,
    DataLibrarry.CouponClaim memory couponClaim
  )
    internal
    pure
  {
    bytes32 digest = getMessageHashForClaim(couponClaim);
    if (_isVerifiedCoupon(digest, coupon) != signer)
      revert ITimeout.InvalidCoupon();
  }

  function getMessageHashForClaim(DataLibrarry.CouponClaim memory couponClaim)
    internal
    pure
    returns(bytes32)
  {
    return keccak256(
      abi.encode(
        couponClaim.user,
        couponClaim.legCount,
        couponClaim.urEggCount,
        couponClaim.urCount,
        couponClaim.basicEggCount,
        couponClaim.basicCount,
        couponClaim.phase
      )
    );
  }

  /**
  * @notice _isVerifiedCoupon verify the coupon
  * @return bool true or false if signature valid
  */
  function _isVerifiedCoupon(bytes32 digest, DataLibrarry.Coupon memory coupon)
    internal
    pure
    returns(address)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    return signer;
  }

  function logicRandomEvo(
    uint8 random,
    uint32 indexEvolutionBlue,
    uint32 indexEvolutionPink,
    uint32 maxSupplyEvo
  )
    internal
    pure
    returns(uint8)
  {
    if (random == 0) {
      if (indexEvolutionBlue > indexEvolutionPink) {
        uint32 plage = indexEvolutionBlue - indexEvolutionPink;
        if (plage > 4) {
          random = 1;
        }
      }
    } else {
      if (indexEvolutionBlue < indexEvolutionPink) {
        uint32 plage = indexEvolutionPink - indexEvolutionBlue;
        if (plage > 4) {
          random = 0;
        }
      }
    }
    if (indexEvolutionBlue >= maxSupplyEvo - 5 && indexEvolutionPink >= maxSupplyEvo - 5) {
      if (indexEvolutionBlue > indexEvolutionPink) {
        uint32 plage = indexEvolutionBlue - indexEvolutionPink;
        if (plage >= 1) {
          random = 1;
        }
      }
      if (indexEvolutionBlue < indexEvolutionPink) {
        uint32 plage = indexEvolutionPink - indexEvolutionBlue;
        if (plage >= 1) {
          random = 0;
        }
      }
    }
    return random;
  }
}