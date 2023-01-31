// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { wadExp, wadMul, unsafeWadMul, toWadUnsafe } from "../utils/SignedWadMath.sol";
import { ISliceProductPrice } from "../Slice/interfaces/utils/ISliceProductPrice.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";

/// @title Variable Rate Gradual Dutch Auction - Slice pricing strategy
/// @author jacopo <[email protected]>
/// @notice Price library with configurable params for each Slice product.

abstract contract VRGDAPrices is ISliceProductPrice {
  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  address internal immutable _productsModuleAddress;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address productsModuleAddress) {
    _productsModuleAddress = productsModuleAddress;
  }

  /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

  /// @notice Check if msg.sender is owner of a product. Used to manage access of `setProductPrice`
  /// in implementations of this contract.
  modifier onlyProductOwner(uint256 slicerId, uint256 productId) {
    require(
      IProductsModule(_productsModuleAddress).isProductOwner(
        slicerId,
        productId,
        msg.sender
      ),
      "NOT_PRODUCT_OWNER"
    );
    _;
  }

  /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Calculate the price of a product according to the VRGDA formula.
  /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
  /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
  /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
  /// @param sold The total number of products sold so far.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @param min minimum price to be paid for a token, scaled by 1e18
  /// @return The price of a product according to VRGDA, scaled by 1e18.
  function getVRGDAPrice(
    int256 targetPrice,
    int256 decayConstant,
    int256 timeSinceStart,
    uint256 sold,
    int256 timeFactor,
    uint256 min
  ) public view virtual returns (uint256) {
    unchecked {
      // prettier-ignore
      uint256 VRGDAPrice = uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // We use sold + 1 as the VRGDA formula's n param represents the nth product and sold is the 
                // n-1th product.
                timeSinceStart - getTargetSaleTime(
                  toWadUnsafe(sold + 1), timeFactor
                )
            ))));

      return VRGDAPrice > min ? VRGDAPrice : min;
    }
  }

  /// @dev Given a number of products sold, return the target time that number of products should be sold by.
  /// @param sold A number of products sold, scaled by 1e18, to get the corresponding target sale time for.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @return The target time the products should be sold by, scaled by 1e18, where the time is
  /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
  function getTargetSaleTime(int256 sold, int256 timeFactor)
    public
    view
    virtual
    returns (int256)
  {}

  /// @notice Get product price adjusted to quantity purchased.
  /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
  /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
  /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
  /// @param sold The total number of products sold so far.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @param min minimum price to be paid for a token, scaled by 1e18
  /// @param quantity Number of units purchased
  /// @return price of product * quantity according to VRGDA, scaled by 1e18.
  function getAdjustedVRGDAPrice(
    int256 targetPrice,
    int256 decayConstant,
    int256 timeSinceStart,
    uint256 sold,
    int256 timeFactor,
    uint256 min,
    uint256 quantity
  ) public view virtual returns (uint256 price) {
    for (uint256 i; i < quantity; ) {
      price += getVRGDAPrice(
        targetPrice,
        decayConstant,
        timeSinceStart,
        sold + i,
        timeFactor,
        min
      );

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Function called by Slice protocol to calculate current product price.
   * @param slicerId ID of the slicer being queried
   * @param productId ID of the product being queried
   * @param currency Currency chosen for the purchase
   * @param quantity Number of units purchased
   * @param buyer Address of the buyer
   * @param data Custom data sent along with the purchase transaction by the buyer
   * @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
  )
    public
    view
    virtual
    override
    returns (uint256 ethPrice, uint256 currencyPrice)
  {}
}