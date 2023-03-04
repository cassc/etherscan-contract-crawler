// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/**
 * @title Interface for structs required in MetaTXs using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines 2 structures (BuyNowInput, AssetTransferResult),
 *  required for the BuyNow processes. These structures require a separate implementation
 *  of their corresponding EIP712-verifying functions.
 */

interface ISignableStructsBuyNow {
    /**
     * @notice The main struct that characterizes a buyNow
     * @dev Used as input to the buyNow method
     * @dev it needs to be signed following EIP712
     */
    struct BuyNowInput {
        // the unique Id that identifies a payment,
        // common to both Auctions and BuyNows,
        // obtained from hashing params related to the listing, 
        // including a sufficiently large source of entropy.
        bytes32 paymentId;

        // the price of the asset, an integer expressed in the
        // lowest unit of the currency.
        uint256 amount;

        // the fee that will be charged by the feeOperator,
        // expressed as percentage Basis Points (bps), applied to amount.
        // e.g. feeBPS = 500 applies a 5% fee.
        uint256 feeBPS;

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // the deadline for the payment to arrive to this
        // contract, otherwise it will be rejected.
        uint256 deadline;

        // the buyer, providing the required funds, who shall receive
        // the asset on a successful payment.
        address buyer;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on a successful payment.
        address seller;
    }

    /**
     * @notice The struct that specifies the success or failure of an asset transfer
     * @dev It needs to be signed by the operator following EIP712
     * @dev Must arrive when the asset is in ASSET_TRANSFERING state, to then move to PAID or REFUNDED
     */
    struct AssetTransferResult {
        // the unique Id that identifies a payment previously initiated in this contract.
        bytes32 paymentId;

        // a bool set to true if the asset was successfully transferred, false otherwise
        bool wasSuccessful;
    }
}