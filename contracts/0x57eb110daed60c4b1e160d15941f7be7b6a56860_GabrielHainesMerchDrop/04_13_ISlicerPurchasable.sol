// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ISlicerPurchasable {
    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @param slicerId ID of the slicer calling the function
     * @param productId ID of the product being purchased
     * @param account Address of the account buying the product
     * @param quantity Amount of products being purchased
     * @param slicerCustomData Custom data sent by slicer during product purchase
     * @param buyerCustomData Custom data sent by buyer during product purchase
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external view returns (bool);

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers.
     *
     * @param slicerId ID of the slicer calling the function
     * @param productId ID of the product being purchased
     * @param account Address of the account buying the product
     * @param quantity Amount of products being purchased
     * @param slicerCustomData Custom data sent by slicer during product purchase
     * @param buyerCustomData Custom data sent by buyer during product purchase
     *
     * @dev Can be inherited by child contracts to add custom logic on product purchases.
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable;
}