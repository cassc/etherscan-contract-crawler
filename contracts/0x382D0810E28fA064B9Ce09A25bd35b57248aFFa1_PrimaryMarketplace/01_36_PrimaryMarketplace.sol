//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "./interface/IPrimaryMarketplace.sol";
import "./Collection.sol";

/**
 * Contract for an ERC-721 primary marketplace.
 * @custom:security-contact [email protected]
 */
contract PrimaryMarketplace is
    Initializable,
    IPrimaryMarketplace,
    EIP712Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /*********/
    /* State */
    /*********/

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * Function used to initialize the contract.
     *
     * @param name The EIP-712 name of the contract used when verifying signed
     *     transaction messages.
     * @param version The EIP-712 version of the contract used when verifying
     *     signed transaction messages.
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     */
    function initialize(
        string memory name,
        string memory version,
        address validator_
    ) public initializer {
        __EIP712_init_unchained(name, version);
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _validator = validator_;
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
    ) external payable nonReentrant whenNotPaused {
        // Ensure the transaction is valid
        _validateTransaction(message, signature);

        // Pay the seller
        _transferPayment(message);

        // Transfer the token to the buyer
        _transferToken(message);

        // Emit event to blockchain
        emit FixedPricePurchased(
            message.paymentReceiver,
            message.tokenReceiver,
            message.payment,
            message.collection,
            message.tokenId
        );
    }

    /**
     * Withdraws a given amount of commission.
     *
     * @param commissionAmount The amount of commission to withdraw.
     */
    function withdrawCommission(
        uint256 commissionAmount
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(this).balance >= commissionAmount,
            "Not enough balance"
        );
        payable(msg.sender).transfer(commissionAmount);
    }

    /**
     * Sets the configurable validator address that will be used when verifying
     * signed transaction messages.
     *
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     */
    function setValidator(
        address validator_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _validator = validator_;
    }

    /**
     * Pauses the contract.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * Unpauses the contract.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /********************/
    /* Public functions */
    /********************/

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
     * Internal function for transferring the payment for a transaction
     * message.
     *
     * @param message The transaction message.
     */
    function _transferPayment(TransactionMessage calldata message) internal {
        message.paymentReceiver.transfer(message.payment);
    }

    /**
     * Abstract internal function responsible for verifying if the seller is
     * the owner of the token being sold.
     *
     * @return Whether or not the seller is the owner of the token being sold.
     */
    function _verifySellerIsOwner(
        TransactionMessage calldata /*message*/
    ) internal pure returns (bool) {
        // In the primary marketplace, the token is unminted yet, so the seller
        // as signed by the validator is considered the owner.
        return true;
    }

    /**
     * Mints a new token and transfers it to the buyer.
     *
     * @param message the Transaction message.
     */
    function _transferToken(TransactionMessage calldata message) internal {
        Collection(message.collection).mintToken(
            message.tokenReceiver,
            message.tokenId,
            message.tokenURI,
            message.royaltyReceiver,
            message.royaltyNumerator
        );
    }

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
    ) private view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "TransactionMessage("
                        "address paymentReceiver,"
                        "address tokenReceiver,"
                        "uint128 payment,"
                        "uint128 commission,"
                        "address collection,"
                        "uint128 tokenId,"
                        "string tokenURI,"
                        "address royaltyReceiver,"
                        "uint16 royaltyNumerator,"
                        "uint256 nonce"
                        ")"
                    ),
                    message.paymentReceiver,
                    message.tokenReceiver,
                    message.payment,
                    message.commission,
                    message.collection,
                    message.tokenId,
                    keccak256(bytes(message.tokenURI)),
                    message.royaltyReceiver,
                    message.royaltyNumerator,
                    message.nonce
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, signature);
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
    ) private {
        // Ensure message is signed by validator
        require(
            _getSigner(message, signature) == _validator,
            "Signature invalid"
        );

        // Ensure message nonce is unused
        require(!_usedNonces[message.nonce], "Nonce already used");

        // Ensure the seller is the owner of what's being sold
        require(_verifySellerIsOwner(message), "Seller is not owner");

        // Ensure the payment is sufficient
        require(
            msg.value >= message.payment + message.commission,
            "Not enough payment"
        );

        // Make sure the nonce can't be used again
        _usedNonces[message.nonce] = true;
    }
}