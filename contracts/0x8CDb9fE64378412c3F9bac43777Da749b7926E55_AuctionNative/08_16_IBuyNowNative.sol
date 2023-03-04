// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./base/IBuyNowBase.sol";

/**
 * @title Interface to Escrow Contract for Payments in BuyNow mode, in native cryptocurrency.
 * @author Freeverse.io, www.freeverse.io
 * @dev The contract that implements this interface adds an entry point for BuyNow payments,
 * which are defined and documented in the inherited IBuyNowBase.
 * - in the 'buyNow' method, the buyer is the msg.sender (the buyer therefore signs the TX),
 *   and the operator's EIP712-signature of the BuyNowInput struct is provided as input to the call.
 */

interface IBuyNowNative is IBuyNowBase {
    /**
     * @notice Starts Payment process by the buyer.
     * @dev Executed by the buyer, who relays the MetaTX with the operator's signature.
     *  The buyer must provide the correct amount via msg.value.
     *  If all requirements are fulfilled, it stores the data relevant
     *  for the next steps of the payment, and it locks the funds
     *  in this contract.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     *  Moves payment to ASSET_TRANSFERRING state.
     * @param buyNowInp The struct containing all required payment data
     * @param operatorSignature The signature of 'buyNowInp' by the operator
     * @param sellerSignature the signature of the seller agreeing to list the asset
     */
    function buyNow(
        BuyNowInput calldata buyNowInp,
        bytes calldata operatorSignature,
        bytes calldata sellerSignature
    ) external payable;
}