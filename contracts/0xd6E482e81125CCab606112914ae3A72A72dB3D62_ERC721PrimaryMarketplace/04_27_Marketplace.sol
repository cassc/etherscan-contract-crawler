//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./IMarketplace.sol";


/**
 * Abstract base contract for marketplaces.
 */
abstract contract Marketplace is
    IMarketplace,
    EIP712,
    AccessControl,
    Pausable,
    ReentrancyGuard
{

    /*********/
    /* State */
    /*********/

    /**
     * Configurable commission numerator used for calculating the commission
     * amount of a transaction.
     */
    uint16 private _commissionNumerator;

    /**
     * Configurable naximum royalty numerator used for verifying the royalty
     * numerator of a transaction.
     */
    uint16 private _maxRoyaltyNumerator;

    /**
     * Internal mapping used to keep track of used nonces.
     */
    mapping(uint256 => bool) private _usedNonces;

    /**
     * Configurable validator address that will be used when verifying signed
     * transaction messages.
     */
    address private _validator;

    /***************/
    /* Constructor */
    /***************/

    /**
     * Creates a new instance of this contract.
     *
     * @param name The EIP-712 name of the contract used when verifying signed
     *     transaction messages.
     * @param version The EIP-712 version of the contract used when verifying
     *     signed transaction messages.
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     * @param commissionNumerator_ The configurable commission numerator that
     *     will be used for calculating the commission amount of a transaction.
     * @param maxRoyaltyNumerator_ The configurable maximum royalty numerator
     *     that will be used for verifying the royalty numerator of a
     *     transaction.
     */
    constructor(
        string memory name,
        string memory version,
        address validator_,
        uint16 commissionNumerator_,
        uint16 maxRoyaltyNumerator_
    )
        EIP712(name, version)
    {
        require(
          commissionNumerator_ + maxRoyaltyNumerator_ <= _getDenominator(),
          "Commission numerator and/or maximum royalty numerator too high"
        );
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _validator = validator_;
         _commissionNumerator = commissionNumerator_;
         _maxRoyaltyNumerator = maxRoyaltyNumerator_;
    }

    /**********************/
    /* External functions */
    /**********************/

    /**
     * Purchases a token for a fixed price.
     *
     * Payable function.
     *
     * @param message The transaction message.
     * @param signature The signature of the transaction message.
     */
    function purchaseFixedPrice(
        TransactionMessage calldata message,
        bytes calldata signature
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {

        // Ensure the transaction is valid
        _validateTransaction(message, signature);

        // Pay the seller
        _transferPayment(message);

        // Transfer the token to the buyer
        _transferToken(message);

        // Emit event to blockchain
        emit FixedPricePurchased(
            message.seller,
            message.buyer,
            message.collection,
            message.tokenId,
            message.tokenAmount,
            message.payment
        );
    }

    /**
     * Sets the configurable commission numerator that will be used for
     * calculating the commission amount of a transaction.
     *
     * Also makes sure that the sum of the current maximum royalty numerator
     * and commission numerator you're about to set does not exceed the
     * denominator.
     *
     * @param commissionNumerator_ The configurable commission numerator that
     *     will be used for calculating the commission amount of a transaction.
     */
    function setCommissionNumerator(uint16 commissionNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
          commissionNumerator_ + _maxRoyaltyNumerator <= _getDenominator(),
          "Commission numerator too high"
        );
        _commissionNumerator = commissionNumerator_;
    }

    /**
     * Withdraws a given amount of commission.
     *
     * @param commissionAmount The amount of commission to withdraw.
     */
    function withdrawCommission(uint256 commissionAmount)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(this).balance >= commissionAmount,
            "Not enough balance"
        );
        payable(msg.sender).transfer(commissionAmount);
    }

    /**
     * Sets the configurable maximum royalty numerator that will be used for
     * verifying the royalty numerator of a transaction.
     *
     * Also makes sure that the sum of the current commission numerator and the
     * maximum royalty numerator you're about to set does not exceed the
     * denominator.
     *
     * @param maxRoyaltyNumerator_ The configurable maximum royalty numerator
     *     that will be used for calculating the commission amount of a
     *     transaction.
     */
    function setMaxRoyaltyNumerator(uint16 maxRoyaltyNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
          _commissionNumerator + maxRoyaltyNumerator_ <= _getDenominator(),
          "Maximum royalty numerator too high"
        );
        _maxRoyaltyNumerator = maxRoyaltyNumerator_;
    }

    /**
     * Sets the configurable validator address that will be used when verifying
     * signed transaction messages.
     *
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     */
    function setValidator(address validator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _validator = validator_;
    }

    /********************/
    /* Public functions */
    /********************/

    /**
     * Returns the configured commission numerator that will be used for
     * calculating the commission amount of a transaction.
     *
     * @return The configured commission numerator that will be used for
     *     calculating the commission amount of a transaction.
     */
    function commissionNumerator() public view returns (uint16) {
        return _commissionNumerator;
    }

    /**
     * Returns the configured maximum royalty numerator that will be used for
     * verifying the royalty numerator of a transaction.
     *
     * @return The configured maximum royalty numerator that will be used for
     *     verifying the royalty amount of a transaction.
     */
    function maxRoyaltyNumerator() public view returns (uint16) {
        return _maxRoyaltyNumerator;
    }

    /**
     * Returns the configurable validator address that will be used when
     * verifying signed transaction messages.
     *
     * @return The configured validator address that will be used when
     *     verifying signed transaction messages.
     */
    function validator() public view returns (address) {
        return _validator;
    }

    /**********************/
    /* Internal functions */
    /**********************/

    /**
     * Internal function used for retrieving the denominator that is applicable
     * to both commission numerators and royalty numerators.
     *
     * @return The denomimator.
     */
    function _getDenominator() internal pure returns (uint16) { return 10000; }

    /**
     * Abstract internal function responsible for returning the royalty
     * numerator that is applicable to a transaction message.
     *
     * @param message The transaction message.
     */
    function _getRoyaltyNumerator(TransactionMessage calldata message)
        internal
        virtual
        returns (uint16);

    /**
     * Abstract internal function responsible for transferring payments to the
     * seller and an additional royalty receiver (if applicable).
     *
     * @param message The transaction message.
     */
    function _transferPayment(TransactionMessage calldata message)
        internal
        virtual;

    /**
     * Abstract internal function responsible for minting a token (if
     * necessary) and transferring it to the buyer.
     *
     * @param message The transaction message.
     */
    function _transferToken(TransactionMessage calldata message)
        internal
        virtual;

    /**
     * Abstract internal function responsible for verifying if the seller is
     * the owner of the token being sold.
     *
     * @param message The transaction message.
     * @return Whether or not the seller is the owner of the token being sold.
     */
    function _verifySellerIsOwner(TransactionMessage calldata message)
        internal
        virtual
        returns (bool);

    /*********************/
    /* Private functions */
    /*********************/

    /**
     * Private function for retrieving the signer address from a transaction
     * message and a signature.
     *
     * If the message and/or signature have been tampered with, an arbitrary
     * address will be returned as the signer address. By making sure the
     * signer address equals the validator address, we can verify the
     * transaction message was signed by the validator and not tampered with.
     *
     * @param message The transaction message.
     * @param signature The signature of the transaction message.
     * @return The retrieved signer address.
     */
    function _getSigner(
        TransactionMessage calldata message,
        bytes calldata signature
    )
        private
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256(
                "TransactionMessage("
                    "address seller,"
                    //"address buyer,"
                    "uint128 payment,"
                    "address collection,"
                    "uint128 tokenId,"
                    "string tokenURI,"
                    "uint256 tokenAmount,"
                    "uint16 royaltyNumerator,"
                    "uint256 nonce"
                ")"
            ),
            message.seller,
            //message.buyer,
            message.payment,
            message.collection,
            message.tokenId,
            keccak256(bytes(message.tokenURI)),
            message.tokenAmount,
            message.royaltyNumerator,
            message.nonce
        )));
        return ECDSA.recover(digest, signature);
    }

    /**
     * Private function validating a transaction.
     *
     * If there is not enough payment, or if the sender is not the buyer, or if
     * the nonce is already used, or if the transaction message and/or
     * signature have been tampered with, the transaction will be reverted.
     *
     * @param message The transaction message.
     * @param signature The signature of the transaction message.
     */
    function _validateTransaction(
        TransactionMessage calldata message,
        bytes calldata signature
    )
        private
    {

        // Ensure message is signed by authic
        require(
            _getSigner(message, signature) == _validator,
            "Signature invalid"
        );

        // Ensure message nonce is unused
        require(!_usedNonces[message.nonce], "Nonce already used");

        // Ensure the seller is the owner of what's being sold
        require(_verifySellerIsOwner(message), "Seller is not owner");

        // Ensure the caller is the buyer
        //require(message.buyer == msg.sender, "Sender is not buyer");

        // Ensure the payment is sufficient
        require(msg.value >= message.payment, "Not enough payment");

        // Ensure the royalty numerator is not too high
        require(
          _getRoyaltyNumerator(message) <= _maxRoyaltyNumerator,
          "Royalty numerator too high"
        );

        // Make sure the nonce can't be used again
        _usedNonces[message.nonce] = true;
    }
}