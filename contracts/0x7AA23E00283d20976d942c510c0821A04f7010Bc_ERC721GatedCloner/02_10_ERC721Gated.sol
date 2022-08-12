// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../extensions/Purchasable/SlicerPurchasableClone.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * Purchase hook with single ERC20 Gate.
 */
contract ERC721Gated is SlicerPurchasableClone {
    /// ============= Storage =============

    IERC721 private _erc721;

    /// ========== Initializer ==========

    /**
     * @notice Initializes the contract.
     *
     * @param productsModuleAddress_ {ProductsModule} address
     * @param slicerId_ ID of the slicer linked to this contract
     * @param erc721_ Address of the ERC721 contract used for gating
     */
    function initialize(
        address productsModuleAddress_,
        uint256 slicerId_,
        IERC721 erc721_
    ) external initializer {
        __SlicerPurchasableClone_init(productsModuleAddress_, slicerId_);
        _erc721 = erc721_;
    }

    /// ============ Functions ============

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * Checks if `account` owns the required amount of ERC20 tokens.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     * @dev Max quantity purchasable per address and total mint amount is handled on Slicer product logic
     */
    function isPurchaseAllowed(
        uint256,
        uint256,
        address account,
        uint256,
        bytes memory,
        bytes memory
    ) public view virtual override returns (bool isAllowed) {
        uint256 accountBalance = _erc721.balanceOf(account);

        isAllowed = accountBalance != 0;
    }

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public payable override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        if (
            !isPurchaseAllowed(
                slicerId,
                productId,
                account,
                quantity,
                slicerCustomData,
                buyerCustomData
            )
        ) revert NotAllowed();
    }
}