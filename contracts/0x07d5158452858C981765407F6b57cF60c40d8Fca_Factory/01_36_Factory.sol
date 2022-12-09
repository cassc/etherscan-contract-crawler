//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "./interface/IFactory.sol";
import "./Collection.sol";

/**
 * Contract for an ERC-721 factory.
 * @custom:security-contact [email protected]
 */
contract Factory is
    Initializable,
    IFactory,
    AccessControlUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable,
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

    /**
     * Configurable marketplace address that will be granted the minter role in
     * created collections.
     */
    address private _marketplace;

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
     * @param marketplace_ The configurable marketplace address that will be
     *     given minter role in created collections.
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
        address marketplace_,
        address validator_
    ) public initializer {
        __EIP712_init_unchained(name, version);
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _marketplace = marketplace_;
        _validator = validator_;
    }

    /**********************/
    /* External functions */
    /**********************/

    /**
     * Mints a new collection.
     *
     * Emits an ERC721CollectionMinted event after completion.
     *
     * @param message The transaction message.
     * @param signature The signature of the transaction message.
     */
    function mintCollection(
        TransactionMessage calldata message,
        bytes calldata signature
    ) external nonReentrant whenNotPaused {

        // Verify the signature.
        _validateTransaction(message, signature);
        
        // Mint the collection.
        Collection collection = new Collection(
            message.name,
            message.symbol,
            msg.sender,
            _marketplace
        );

        emit ERC721CollectionMinted(
            message.transactionId,
            message.name,
            message.symbol,
            address(collection),
            msg.sender
        );
    }

    /**
     * Sets the configurable marketplace address that will be given the minter
     * role in created collections.
     *
     * @param marketplace_ The marketplace address that will be given minter
     *     role in created collections.
     */
    function setMarketplace(
        address marketplace_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _marketplace = marketplace_;
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

    /**
     * Returns the configured marketplace address that will be given the minter
     * role in created collections.
     *
     * @return The configured marketplace address that will be given minter
     *     role in created collections.
     */
    function marketplace() public view returns (address) {
        return _marketplace;
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
                            "uint256 transactionId,"
                            "string name,"
                            "string symbol,"
                            "uint256 nonce"
                        ")"
                    ),
                    message.transactionId,
                    keccak256(bytes(message.name)),
                    keccak256(bytes(message.symbol)),
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

        // Make sure the nonce can't be used again
        _usedNonces[message.nonce] = true;
    }

}