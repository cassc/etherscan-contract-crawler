// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubSlicerProduct.sol";
import "./CurrencyPrice.sol";

struct ProductParams {
    SubSlicerProduct[] subSlicerProducts;
    CurrencyPrice[] currencyPrices;
    bytes data;
    bytes purchaseData;
    uint32 availableUnits;
    // uint32 categoryIndex;
    uint8 maxUnitsPerBuyer;
    bool isFree;
    bool isInfinite;
    bool isExternalCallPaymentRelative;
    bool isExternalCallPreferredToken;
}