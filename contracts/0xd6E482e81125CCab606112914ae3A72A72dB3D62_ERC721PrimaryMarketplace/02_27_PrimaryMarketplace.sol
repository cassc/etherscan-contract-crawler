//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Marketplace.sol";


/**
 * Abstract base contract for primary marketplaces.
 */
abstract contract PrimaryMarketplace is Marketplace {

    /**********************/
    /* Internal functions */
    /**********************/

    /**
     * Returns the royalty numerator by extracting it from the transaction
     * message (Since the token is still unminted).
     *
     * @param message The transaction message.
     * @return The royalty numerator.
     */
    function _getRoyaltyNumerator(TransactionMessage calldata message)
        internal
        pure
        override
        returns (uint16)
    {
        return message.royaltyNumerator;
    }

    /**
     * Internal function for transferring the payment for a transaction
     * message.
     *
     * The payment will split according to the following rules:
     * - The commission amount is kept in the contract.
     * - The payment minus the commission amount is sent to the seller.
     *
     * @param message The transaction message.
     */
    function _transferPayment(TransactionMessage calldata message)
        internal
        override
    {
        uint256 commissionAmount = (
            message.payment * commissionNumerator()
        ) / _getDenominator();

        message.seller.transfer(message.payment - commissionAmount);
    }

    /**
     * Abstract internal function responsible for verifying if the seller is
     * the owner of the token being sold.
     *
     * @return Whether or not the seller is the owner of the token being sold.
     */
    function _verifySellerIsOwner(TransactionMessage calldata /*message*/)
        internal
        pure
        override
        returns (bool)
    {
        // In the primary marketplace, the token is unminted yet, so the seller
        // as signed by the validator is considered the owner.
        return true;
    }
}