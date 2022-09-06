// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.14;

library DataLibrary {
 enum SalePhase {
    Phase01,
    Phase02,
    Phase03,
    Phase04,
    Phase05
  }

  enum CouponType {
    HQWL,
    MuseumWL,
    MansionWL,
    PrivateWL,
    PublicWL,
    ReservedWL
  }

  enum NftType {
    None,
    Hq,
    Museum,
    Mansion
  }

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct InternVar {
    uint256 price;
    uint256 expectedPrice;
    uint16 quantity;
    uint256 hqPrice;
    uint256 museumPrice;
    uint256 mansionPrice;
    uint16 mintsWalletCount;
  }

  address public constant _adminSigner = 0x8345b7C47CA83De149b672472962cc6d6B7A8D70; 
  address public constant crossMintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
  address public constant landzAddress = 0xf15Fe77814aaBD9E71691948f3289F8438679a96;
  address public constant giveAwayAddress = 0xB9e0beEE9CFc48C1E53442baB96371DcAd9c3cB2;
  address public constant advisorA = 0x3F9ed7b1b3C2A70169D0122DfDD95CE2662b82D6;
  address public constant advisorB = 0x419e90565Db6D2222b93841e38e586cbB1f8a5ee;
  address public constant advisorC = 0x5d77679942eafB5E2C1958D115F4f9508311067d;
  address public constant advisorD = 0x3483fD757C3F6718971aC59219a743C170E8FE32;
}

library Library {
  /// @notice _isVerifiedCoupon verify the coupon

  function isVerifiedCoupon(bytes32 digest, DataLibrary.Coupon memory coupon)
  internal
  pure
  returns(bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "016"); // Added check for zero address
    return signer == DataLibrary._adminSigner;
  }

  function checkSupply(
    uint16 hqIndex,
    uint16 museumIndex,
    uint16 mensionIndex,
    uint16 quantityHq,
    uint16 quantityMuseum,
    uint16 quantityMansion,
    uint16 maxSupplyHq,
    uint16 maxSupplyMuseum,
    uint16 maxSupplyMansion
  )
    internal
    pure
  {
    require(hqIndex + quantityHq < maxSupplyHq + 1
      , "002");
    require(museumIndex + quantityMuseum < maxSupplyMuseum + 1
      , "003");
    require(mensionIndex + quantityMansion < maxSupplyMansion + 1
      , "004");
  }
}