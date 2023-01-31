// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../structs/Function.sol";
import "../structs/Price.sol";
import "../structs/ProductParams.sol";
import "../structs/PurchaseParams.sol";
import "./ISliceCore.sol";
import "./IFundsModule.sol";

interface IProductsModule {
  function sliceCore() external view returns (ISliceCore sliceCoreAddress);

  function fundsModule()
    external
    view
    returns (IFundsModule fundsModuleAddress);

  function addProduct(
    uint256 slicerId,
    ProductParams memory params,
    Function memory externalCall_
  ) external;

  function setProductInfo(
    uint256 slicerId,
    uint256 productId,
    uint8 newMaxUnits,
    bool isFree,
    bool isInfinite,
    uint32 newUnits,
    CurrencyPrice[] memory currencyPrices
  ) external;

  function removeProduct(uint256 slicerId, uint256 productId) external;

  function payProducts(address buyer, PurchaseParams[] calldata purchases)
    external
    payable;

  function releaseEthToSlicer(uint256 slicerId) external;

  // function _setCategoryAddress(uint256 categoryIndex, address newCategoryAddress) external;

  function ethBalance(uint256 slicerId) external view returns (uint256);

  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
  ) external view returns (Price memory price);

  function validatePurchaseUnits(
    address account,
    uint256 slicerId,
    uint256 productId
  ) external view returns (uint256 purchases);

  function validatePurchase(uint256 slicerId, uint256 productId)
    external
    view
    returns (uint256 purchases, bytes memory purchaseData);

  function availableUnits(uint256 slicerId, uint256 productId)
    external
    view
    returns (uint256 units, bool isInfinite);

  function isProductOwner(
    uint256 slicerId,
    uint256 productId,
    address account
  ) external view returns (bool isAllowed);

  // function categoryAddress(uint256 categoryIndex) external view returns (address);
}