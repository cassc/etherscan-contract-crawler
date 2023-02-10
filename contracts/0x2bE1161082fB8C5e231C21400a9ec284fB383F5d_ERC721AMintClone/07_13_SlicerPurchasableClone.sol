// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./SlicerPurchasable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SlicerPurchasable
 * @author jjranalli
 *
 * @notice Extension enabling basic usage of external calls by slicers upon product purchase.
 */
abstract contract SlicerPurchasableClone is SlicerPurchasable, Initializable {
    /// ========== Initializer ==========

    /**
     * @notice Initializes the contract.
     *
     * @param productsModuleAddress_ {ProductsModule} address
     * @param slicerId_ ID of the slicer linked to this contract
     */
    function __SlicerPurchasableClone_init(
        address productsModuleAddress_,
        uint256 slicerId_
    ) internal onlyInitializing {
        _productsModuleAddress = productsModuleAddress_;
        _slicerId = slicerId_;
    }

    /**
     * @notice Add delegate call check
     */
    function _onlyOnPurchaseFrom(uint256 slicerId) internal view virtual override {
        super._onlyOnPurchaseFrom(slicerId);
    }
}