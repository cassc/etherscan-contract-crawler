// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./SlicerPurchasable.sol";

/**
 * @title SlicerPurchasable
 * @author jjranalli
 *
 * @notice Extension enabling basic usage of external calls by slicers upon product purchase.
 */
abstract contract SlicerPurchasableConstructor is SlicerPurchasable {
    /// =============== Errors ==============

    error NoDelegatecall();

    /// ========= Immutable storage =========

    address immutable original;

    /// ============ Constructor ============

    /**
     * @notice Initializes the contract.
     *
     * @param productsModuleAddress_ {ProductsModule} address
     * @param slicerId_ ID of the slicer linked to this contract
     */
    constructor(address productsModuleAddress_, uint256 slicerId_) {
        _productsModuleAddress = productsModuleAddress_;
        _slicerId = slicerId_;
        original = address(this);
    }

    /**
     * @notice Add delegate call check
     */
    function _onlyOnPurchaseFrom(uint256 slicerId) internal view virtual override {
        super._onlyOnPurchaseFrom(slicerId);
        if (address(this) != original) revert NoDelegatecall();
    }
}