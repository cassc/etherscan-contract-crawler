// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { wadMul, toWadUnsafe, wadLn, unsafeWadDiv, toDaysWadUnsafe, unsafeDiv, wadExp, unsafeWadMul } from "../utils/SignedWadMath.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";
import { LogisticProductParams } from "./structs/LogisticProductParams.sol";
import { LogisticVRGDAParams } from "./structs/LogisticVRGDAParams.sol";

import { VRGDAPrices } from "./VRGDAPrices.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction - Slice pricing strategy
/// @author jacopo <[email protected]>
/// @notice VRGDA with a logistic issuance curve - Price library with different params for each Slice product.
contract LogisticVRGDAPrices is VRGDAPrices {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  // Mapping from slicerId to productId to LogisticProductParams
  mapping(uint256 => mapping(uint256 => LogisticProductParams))
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
  /// @param logisticParams see `LogisticVRGDAParams`.
  /// @param priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
  /// which affects how quickly we will reach the curve's asymptote, scaled by 1e18.
  function setProductPrice(
    uint256 slicerId,
    uint256 productId,
    address[] calldata currencies,
    LogisticVRGDAParams[] calldata logisticParams,
    int256 priceDecayPercent
  ) external onlyProductOwner(slicerId, productId) {
    require(logisticParams.length == currencies.length, "INVALID_INPUTS");

    int256 decayConstant = wadLn(1e18 - priceDecayPercent);
    // The decay constant must be negative for VRGDAs to work.
    require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    require(decayConstant >= type(int184).min, "MIN_DECAY_CONSTANT_EXCEEDED");

    // Get product availability and isInfinite
    (uint256 availableUnits, bool isInfinite) = IProductsModule(
      _productsModuleAddress
    ).availableUnits(slicerId, productId);

    // Product must not have infinite availability
    require(!isInfinite, "NON_FINITE_AVAILABILITY");

    // Set product params
    _productParams[slicerId][productId].startTime = uint40(block.timestamp);
    _productParams[slicerId][productId].startUnits = uint32(availableUnits);
    _productParams[slicerId][productId].decayConstant = int184(decayConstant);

    // Set currency params
    for (uint256 i; i < currencies.length; ) {
      _productParams[slicerId][productId].pricingParams[
        currencies[i]
      ] = logisticParams[i];

      unchecked {
        ++i;
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Same as `getVRGDAPrice` but which additionally accepts `logisticLimit` and
  /// `logisticLimitDouble` as param.
  /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
  /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
  /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
  /// @param logisticLimit The maximum number of products to sell + 1.
  /// @param logisticLimitDouble The maximum number of products to sell + 1 multiplied by 2.
  /// @param sold The total number of products sold so far.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @param min minimum price to be paid for a token, scaled by 1e18
  /// @return The price of a product according to VRGDA, scaled by 1e18.
  function getVRGDALogisticPrice(
    int256 targetPrice,
    int256 decayConstant,
    int256 timeSinceStart,
    int256 logisticLimit,
    int256 logisticLimitDouble,
    uint256 sold,
    int256 timeFactor,
    uint256 min
  ) public pure returns (uint256) {
    unchecked {
      // prettier-ignore
      uint256 VRGDAPrice = uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
          // We use sold + 1 as the VRGDA formula's n param represents the nth product and sold is the 
          // n-1th product.
          timeSinceStart - getTargetSaleTime(
            unsafeDiv(
              logisticLimitDouble, 
              toWadUnsafe(sold + 1) + logisticLimit
            ), timeFactor
          )
      ))));

      return VRGDAPrice > min ? VRGDAPrice : min;
    }
  }

  /// @notice Get product price adjusted to quantity purchased.
  /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
  /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
  /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
  /// @param logisticLimit The maximum number of products to sell + 1.
  /// @param sold The total number of products sold so far.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @param min minimum price to be paid for a token, scaled by 1e18
  /// @param quantity Number of units purchased
  /// @return price of product * quantity according to VRGDA, scaled by 1e18.
  function getAdjustedVRGDALogisticPrice(
    int256 targetPrice,
    int256 decayConstant,
    int256 timeSinceStart,
    int256 logisticLimit,
    uint256 sold,
    int256 timeFactor,
    uint256 min,
    uint256 quantity
  ) public pure returns (uint256 price) {
    int256 logisticLimitDouble = logisticLimit * 2e18;
    for (uint256 i; i < quantity; ) {
      price += getVRGDALogisticPrice(
        targetPrice,
        decayConstant,
        timeSinceStart,
        logisticLimit,
        logisticLimitDouble,
        sold + i,
        timeFactor,
        min
      );

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Given a number of products sold, return the target time that number of products should be sold by.
  /// @param saleFactor Sales-dependent factor used to calculate target sale time.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @return The target time the products should be sold by, scaled by 1e18, where the time is
  /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
  function getTargetSaleTime(int256 saleFactor, int256 timeFactor)
    public
    pure
    override
    returns (int256)
  {
    unchecked {
      return -unsafeWadDiv(wadLn(saleFactor - 1e18), timeFactor);
    }
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
    LogisticProductParams storage productParams = _productParams[slicerId][
      productId
    ];
    LogisticVRGDAParams memory pricingParams = productParams.pricingParams[
      currency
    ];

    require(productParams.startTime != 0, "PRODUCT_UNSET");

    // Get available units
    (uint256 availableUnits, ) = IProductsModule(_productsModuleAddress)
      .availableUnits(slicerId, productId);

    // Set ethPrice or currencyPrice based on chosen currency
    if (currency == address(0)) {
      ethPrice = getAdjustedVRGDALogisticPrice(
        pricingParams.targetPrice,
        productParams.decayConstant,
        toDaysWadUnsafe(block.timestamp - productParams.startTime),
        toWadUnsafe(productParams.startUnits + 1),
        productParams.startUnits - availableUnits,
        pricingParams.timeScale,
        pricingParams.min,
        quantity
      );
    } else {
      currencyPrice = getAdjustedVRGDALogisticPrice(
        pricingParams.targetPrice,
        productParams.decayConstant,
        toDaysWadUnsafe(block.timestamp - productParams.startTime),
        toWadUnsafe(productParams.startUnits + 1),
        productParams.startUnits - availableUnits,
        pricingParams.timeScale,
        pricingParams.min,
        quantity
      );
    }
  }
}