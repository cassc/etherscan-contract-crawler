// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { wadLn, unsafeWadDiv, toDaysWadUnsafe } from "../utils/SignedWadMath.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";
import { LinearProductParams } from "./structs/LinearProductParams.sol";
import { LinearVRGDAParams } from "./structs/LinearVRGDAParams.sol";

import { VRGDAPrices } from "./VRGDAPrices.sol";

/// @title Linear Variable Rate Gradual Dutch Auction - Slice pricing strategy
/// @author jacopo <[email protected]>
/// @notice VRGDA with a linear issuance curve - Price library with different params for each Slice product.
contract LinearVRGDAPrices is VRGDAPrices {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  // Mapping from slicerId to productId to ProductParams
  mapping(uint256 => mapping(uint256 => LinearProductParams))
    private _productParams;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address productsModuleAddress)
    VRGDAPrices(productsModuleAddress)
  {}

  /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

  /// @notice Set LinearProductParams for product.
  /// @param slicerId ID of the slicer to set the price params for.
  /// @param productId ID of the product to set the price params for.
  /// @param currencies currencies of the product to set the price params for.
  /// @param linearParams see `LinearVRGDAParams`.
  /// @param priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
  function setProductPrice(
    uint256 slicerId,
    uint256 productId,
    address[] calldata currencies,
    LinearVRGDAParams[] calldata linearParams,
    int256 priceDecayPercent
  ) external onlyProductOwner(slicerId, productId) {
    require(linearParams.length == currencies.length, "INVALID_INPUTS");

    int256 decayConstant = wadLn(1e18 - priceDecayPercent);
    // The decay constant must be negative for VRGDAs to work.
    require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    require(decayConstant >= type(int184).min, "MIN_DECAY_CONSTANT_EXCEEDED");

    /// Get product availability and isInfinite
    /// @dev available units is a uint32
    (uint256 availableUnits, bool isInfinite) = IProductsModule(
      _productsModuleAddress
    ).availableUnits(slicerId, productId);

    // Product must not have infinite availability
    require(!isInfinite, "NOT_FINITE_AVAILABILITY");

    // Set product params
    _productParams[slicerId][productId].startTime = uint40(block.timestamp);
    _productParams[slicerId][productId].startUnits = uint32(availableUnits);
    _productParams[slicerId][productId].decayConstant = int184(decayConstant);

    // Set currency params
    for (uint256 i; i < currencies.length; ) {
      _productParams[slicerId][productId].pricingParams[
        currencies[i]
      ] = linearParams[i];

      unchecked {
        ++i;
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @dev Given a number of products sold, return the target time that number of products should be sold by.
  /// @param sold A number of products sold, scaled by 1e18, to get the corresponding target sale time for.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @return The target time the products should be sold by, scaled by 1e18, where the time is
  /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
  function getTargetSaleTime(int256 sold, int256 timeFactor)
    public
    pure
    override
    returns (int256)
  {
    return unsafeWadDiv(sold, timeFactor);
  }

  /**
   * @notice Function called by Slice protocol to calculate current product price.
   * @param slicerId ID of the slicer being queried
   * @param productId ID of the product being queried
   * @param currency Currency chosen for the purchase
   * @param quantity Number of units purchased
   * @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address,
    bytes memory
  ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    // Add reference for product and pricing params
    LinearProductParams storage productParams = _productParams[slicerId][
      productId
    ];
    LinearVRGDAParams memory pricingParams = productParams.pricingParams[
      currency
    ];

    require(productParams.startTime != 0, "PRODUCT_UNSET");

    // Get available units
    (uint256 availableUnits, ) = IProductsModule(_productsModuleAddress)
      .availableUnits(slicerId, productId);

    // Calculate sold units from availableUnits
    uint256 soldUnits = productParams.startUnits - availableUnits;

    // Set ethPrice or currencyPrice based on chosen currency
    if (currency == address(0)) {
      ethPrice = getAdjustedVRGDAPrice(
        pricingParams.targetPrice,
        productParams.decayConstant,
        toDaysWadUnsafe(block.timestamp - productParams.startTime),
        soldUnits,
        pricingParams.perTimeUnit,
        pricingParams.min,
        quantity
      );
    } else {
      currencyPrice = getAdjustedVRGDAPrice(
        pricingParams.targetPrice,
        productParams.decayConstant,
        toDaysWadUnsafe(block.timestamp - productParams.startTime),
        soldUnits,
        pricingParams.perTimeUnit,
        pricingParams.min,
        quantity
      );
    }
  }
}