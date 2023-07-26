// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IFeralfileSaleData.sol";

contract FeralfileSaleData is IFeralfileSaleData {
    function validateSaleData(SaleData calldata saleData_) internal view {
        require(
            saleData_.tokenIds.length > 0,
            "FeralfileSaleData: tokenIds is empty"
        );
        require(
            saleData_.tokenIds.length == saleData_.revenueShares.length,
            "FeralfileSaleData: tokenIds and revenueShares length mismatch"
        );
        require(
            saleData_.expiryTime > block.timestamp,
            "FeralfileSaleData: sale is expired"
        );
    }
}