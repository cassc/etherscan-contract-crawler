// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
/**
 * @title Invoice Interface
 * @notice These structures are used to describe an instance of an invoice.
 * @dev The storage of invoices is managed in Invoice.sol in the `invoices` variable.
*/
interface IInvoice {
    /** 
    * @notice This interface contains a data structure that describes the payment rules for an invoice. 
    * @dev This data is used to validate the payment transaction, determine the state of the invoice, and so on. This data is formed from the input of the invoice creator.
    * @param amount Amount to be paid
    * @param unitOfAccount The address of the token contract that can be used to make the payment (a zero address assumes payment in native ETH)
    * @param expirationBlock The block at which the invoice expires
    * @param description Description of the invoice
    * @param whitelist A whitelist of payers. An empty array denotes a public invoice.
    */
    struct InvoiceCore {
        uint256 amount;
        address unitOfAccount;
        uint256 expirationBlock;
        string description;
        address[] whitelist;
    }
    /**
    * @notice This interface is used to store complete records of invoices, including their current state, metadata, and payment rules.
    * @dev This data is automatically formed when the invoice is created and changes when state-changing transactions are executed.
    * @param core Payment rules (user input)
    * @param invoiceId Invoice identifier
    * @param createdBy The creator of the invoice
    * @param isPaid Flag indicating whether the invoice has been successfully paid
    * @param isCanceled Flag indicating whether the invoice has been canceled
    */
    struct InvoiceInfo {
        InvoiceCore core;
        uint256 invoiceId;
        address createdBy;
        bool isPaid;
        bool isCanceled;
    }
    /**
    * @notice Encoding the states of an individual invoice
    * @dev None - for a non-existent invoice, Paid, Expired, Canceled - are completed invoice states where payment is not possible.
    */
    enum InvoiceState {
        None,
        Active,
        Paid,
        Expired,
        Canceled
    }

    function createInvoice(address pool, InvoiceCore memory core) external;

    function payInvoice(address pool, uint256 invoiceId) external payable;

    function cancelInvoice(address pool, uint256 invoiceId) external;

    function setInvoiceCanceled(address pool, uint256 invoiceId) external;
}