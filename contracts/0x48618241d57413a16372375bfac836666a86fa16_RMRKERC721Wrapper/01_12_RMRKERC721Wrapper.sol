//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/access/Ownable.sol";
import "./IRMRKWrappedEquippable.sol";
import "./IRMRKERC721WrapperDeployer.sol";
import "./IRMRKRegistry.sol";
import "./IRMRKWrapRegistry.sol";

error CollectionAlreadyWrapped();
error CollectionIsNotWrapped();
error NotEnoughAllowance();
error OnlyCollectionOwnerCanWrapOrUnwrap();
error InvalidPaymentToken();

/**
 * @title RMRK ERC721 Wrapper
 * @notice This contract is used to wrap ERC721 collections.
 * @dev Only the owner of the collection can wrap it.
 */
contract RMRKERC721Wrapper is Ownable {
    /**
     * @notice Emitted when a collection is wrapped.
     * @param originalCollection The address of the original collection
     * @param wrappedCollection The address of the newly deployed wrapped collection
     * @param prepaidForTokens Whether the collection owner prepaid for individual token wraps
     */
    event WrappedCollection(
        address indexed originalCollection,
        address indexed wrappedCollection,
        bool prepaidForTokens
    );
    /**
     * @notice Emitted when a collection is unwrapped.
     * @param originalCollection The address of the original collection
     * @param wrappedCollection The address of the abandoned wrapped collection
     */
    event UnwrappedCollection(
        address indexed originalCollection,
        address indexed wrappedCollection
    );

    event ValidPaymentTokenSet(
        address indexed paymentToken,
        bool indexed valid
    );

    uint8 CUSTOM_MINTING_TYPE_FROM_WRAPPER = 2;
    IRMRKERC721WrapperDeployer private _deployer;
    IRMRKWrapRegistry private _wrapRegistry;
    address private _beneficiary;
    address private _registry;
    uint256 private _prepayDiscountBPS;
    IRMRKRegistry.CollectionConfig private _defaultCollectionConfig;
    address[] private _validPaymentTokensList;

    mapping(address paymentToken => bool valid) private _validPaymentTokens;
    mapping(address paymentToken => uint256 collectionWrappingPrice)
        private _collectionWrappingPrice;
    mapping(address paymentToken => uint256 individualWrappingPrice)
        private _individualWrappingPrice;

    modifier onlyValidPaymentToken(address paymentToken) {
        _checkValidPaymentToken(paymentToken);
        _;
    }

    /**
     * @notice Initializes the contract.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param prepayDiscountBPS The discount in basis points when prepaying for individual token wraps
     * @param beneficiary The address of the beneficiary
     * @param deployer The address of the deployer contract
     */
    constructor(
        uint256 prepayDiscountBPS,
        address beneficiary,
        address deployer,
        address registry
    ) {
        _prepayDiscountBPS = prepayDiscountBPS;
        _beneficiary = beneficiary;
        _deployer = IRMRKERC721WrapperDeployer(deployer);
        _registry = registry;

        _defaultCollectionConfig = IRMRKRegistry.CollectionConfig(
            true,
            false,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            0,
            CUSTOM_MINTING_TYPE_FROM_WRAPPER,
            0x0
        );
    }

    // -------------- GETTERS --------------

    /**
     * @notice Returns the address of the ERC20 token used for payment.
     * @param paymentToken The address of the ERC20 token used for payment
     * @return erc20TokenAddress The address of the ERC20 token used for payment
     */
    function getIsValidPaymentToken(
        address paymentToken
    ) public view returns (bool) {
        return _validPaymentTokens[paymentToken];
    }

    /**
     * @notice Returns the list of valid payment tokens.
     * @return validPaymentTokensList The list of valid payment tokens
     */
    function getAllValidPaymentTokens() public view returns (address[] memory) {
        return _validPaymentTokensList;
    }

    /**
     * @notice Returns the price of wrapping a collection.
     * @param paymentToken The address of the ERC20 token used for payment
     * @return collectionWrappingPrice The price of wrapping a collection
     */
    function getCollectionWrappingPrice(
        address paymentToken
    ) public view onlyValidPaymentToken(paymentToken) returns (uint256) {
        return _collectionWrappingPrice[paymentToken];
    }

    /**
     * @notice Returns the price of wrapping an individual token.
     * @param paymentToken The address of the ERC20 token used for payment
     * @return individualWrappingPrice The price of wrapping an individual token
     */
    function getIndividualWrappingPrice(
        address paymentToken
    ) public view onlyValidPaymentToken(paymentToken) returns (uint256) {
        return _individualWrappingPrice[paymentToken];
    }

    /**
     * @notice Returns the discount in basis points when prepaying for individual token wraps.
     * @return prepayDiscountBPS The discount in basis points when prepaying for individual token wraps
     */
    function getPrepayDiscountBPS() public view returns (uint256) {
        return _prepayDiscountBPS;
    }

    /**
     * @notice Returns the address of the beneficiary.
     * @return beneficiary The address of the beneficiary
     */
    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @notice Returns the address of the deployer contract.
     * @return deployer The address of the deployer contract
     */
    function getDeployer() public view returns (address) {
        return address(_deployer);
    }

    /**
     * @notice Returns the address of the registry contract.
     * @return registry The address of the registry contract
     */
    function getRegistry() public view returns (address) {
        return _registry;
    }

    /**
     * @notice Returns the address of the wrap registry contract.
     * @return Address of the wrap registry smart contract
     */
    function getWrapRegistry() public view returns (address) {
        return address(_wrapRegistry);
    }

    /**
     * @notice Returns the address of the wrapped collection corresponding to an original collection.
     * @param originalCollection The address of the original collection
     * @return wrappedCollection The address of the wrapped collection
     */
    function getWrappedCollection(
        address originalCollection
    ) public view returns (address wrappedCollection) {
        return _wrapRegistry.getWrappedCollection(originalCollection);
    }

    /**
     * @notice Returns the address of the original collection corresponding to a wrapped collection.
     * @param wrappedCollection The address of the wrapped collection
     * @return originalCollection The address of the original collection
     */
    function getOriginalCollection(
        address wrappedCollection
    ) public view returns (address originalCollection) {
        return _wrapRegistry.getOriginalCollection(wrappedCollection);
    }

    // -------------- ADMIN SETTERS --------------

    /**
     * @notice Sets whether a payment token is valid.
     * @param paymentToken The address of the ERC20 token used for payment
     * @param valid Whether the payment token is valid
     */
    function setValidPaymentToken(
        address paymentToken,
        bool valid
    ) public onlyOwnerOrContributor {
        if (_validPaymentTokens[paymentToken] == valid) return;
        if (_validPaymentTokens[paymentToken]) {
            // Removing
            for (uint256 i; i < _validPaymentTokensList.length; ) {
                if (_validPaymentTokensList[i] == paymentToken) {
                    _validPaymentTokensList[i] = _validPaymentTokensList[
                        _validPaymentTokensList.length - 1
                    ];
                    _validPaymentTokensList.pop();
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            // Adding
            _validPaymentTokensList.push(paymentToken);
        }
        _validPaymentTokens[paymentToken] = valid;
        emit ValidPaymentTokenSet(paymentToken, valid);
    }

    /**
     * @notice Sets the prices of wrapping a collection and individual tokens.
     * @param paymentToken The address of the ERC20 token used for payment
     * @param collectionWrappingPrice The price of wrapping a collection
     * @param individualWrappingPrice The price of wrapping an individual token
     */
    function setPricesForPaymentToken(
        address paymentToken,
        uint256 collectionWrappingPrice,
        uint256 individualWrappingPrice
    ) public onlyOwnerOrContributor {
        setValidPaymentToken(paymentToken, true);
        _collectionWrappingPrice[paymentToken] = collectionWrappingPrice;
        _individualWrappingPrice[paymentToken] = individualWrappingPrice;
    }

    /**
     * @notice Sets the discount in basis points when prepaying for individual token wraps.
     * @param prepayDiscountBPS The discount in basis points when prepaying for individual token wraps
     */
    function setPrepayDiscountBPS(
        uint256 prepayDiscountBPS
    ) public onlyOwnerOrContributor {
        _prepayDiscountBPS = prepayDiscountBPS;
    }

    /**
     * @notice Sets the address of the beneficiary.
     * @param beneficiary The address of the beneficiary
     */
    function setBeneficiary(address beneficiary) public onlyOwner {
        _beneficiary = beneficiary;
    }

    /**
     * @notice Sets the address of the deployer contract.
     * @param deployer The address of the deployer contract
     */
    function setDeployer(address deployer) public onlyOwnerOrContributor {
        _deployer = IRMRKERC721WrapperDeployer(deployer);
    }

    /**
     * @notice Sets the address of the registry contract.
     * @param registry The address of the registry contract
     */
    function setRegistry(address registry) public onlyOwnerOrContributor {
        _registry = registry;
    }

    /**
     * @notice Sets the address of the wrap registry contract.
     * @param wrapRegistry The address of the wrap registry contract
     */
    function setWrapRegistry(
        address wrapRegistry
    ) public onlyOwnerOrContributor {
        _wrapRegistry = IRMRKWrapRegistry(wrapRegistry);
    }

    // -------------- WRAPPING --------------

    /**
     * @notice Wraps a collection.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param originalCollection The address of the original collection
     * @param maxSupply The maximum supply of the wrapped collection
     * @param royaltiesRecipient The address of the royalties recipient
     * @param royaltyPercentageBps The royalty percentage in basis points
     * @param collectionMetadataURI The metadata URI of the wrapped collection
     * @param paymentToken The address of the ERC20 token used for payment
     * @param prePayTokenWraps Whether to prepay for individual token wraps
     */
    function wrapCollection(
        address originalCollection,
        uint256 maxSupply,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory collectionMetadataURI,
        address paymentToken,
        bool prePayTokenWraps
    ) external onlyValidPaymentToken(paymentToken) {
        if (getWrappedCollection(originalCollection) != address(0))
            revert CollectionAlreadyWrapped();

        address collectionOwner = Ownable(originalCollection).owner();
        if (collectionOwner != _msgSender())
            revert OnlyCollectionOwnerCanWrapOrUnwrap();

        uint256 individualPrice = _chargeAndGetIndividualPrice(
            paymentToken,
            maxSupply,
            prePayTokenWraps
        );

        address wrappedCollection = _deployer.wrapCollection(
            originalCollection,
            maxSupply,
            royaltiesRecipient,
            royaltyPercentageBps,
            collectionMetadataURI
        );
        IRMRKWrappedEquippable(wrappedCollection).setPaymentData(
            paymentToken,
            individualPrice,
            _beneficiary
        );
        IRMRKRegistry(_registry).addCollection(
            wrappedCollection,
            _msgSender(),
            maxSupply,
            IRMRKRegistry.LegoCombination.Equippable,
            IRMRKRegistry.MintingType.Custom,
            false,
            _defaultCollectionConfig,
            collectionMetadataURI
        );
        Ownable(wrappedCollection).transferOwnership(collectionOwner);

        _wrapRegistry.setOriginalAndWrappedCollection(
            originalCollection,
            wrappedCollection
        );

        emit WrappedCollection(
            originalCollection,
            wrappedCollection,
            prePayTokenWraps
        );
    }

    /**
     * @notice Unwraps a collection.
     * @param originalCollection The address of the original collection
     */
    function unwrapCollection(address originalCollection) external {
        address wrapped = getWrappedCollection(originalCollection);
        if (wrapped == address(0)) revert CollectionIsNotWrapped();

        address collectionOwner = Ownable(originalCollection).owner();
        if (collectionOwner != _msgSender())
            revert OnlyCollectionOwnerCanWrapOrUnwrap();

        _wrapRegistry.removeWrappedCollection(originalCollection);

        emit UnwrappedCollection(originalCollection, wrapped);
    }

    function _chargeAndGetIndividualPrice(
        address paymentToken,
        uint256 maxSupply,
        bool prePayTokenWraps
    ) private returns (uint256) {
        uint256 totalPrice = _collectionWrappingPrice[paymentToken];
        uint256 individualPrice = _individualWrappingPrice[paymentToken];
        if (prePayTokenWraps) {
            totalPrice +=
                (individualPrice * maxSupply * _prepayDiscountBPS) /
                10000;
            individualPrice = 0;
        }
        _chargeWrappingFee(paymentToken, _msgSender(), totalPrice);
        return individualPrice;
    }

    /**
     * @notice Charges the wrapping fee and sends it to the beneficiary.
     * @param chargeTo The address to charge the fee to
     * @param value The amount to charge
     */
    function _chargeWrappingFee(
        address paymentToken,
        address chargeTo,
        uint256 value
    ) private {
        if (value == 0) return;
        if (IERC20(paymentToken).allowance(chargeTo, address(this)) < value)
            revert NotEnoughAllowance();
        IERC20(paymentToken).transferFrom(chargeTo, _beneficiary, value);
    }

    function _checkValidPaymentToken(address paymentToken) private view {
        if (!_validPaymentTokens[paymentToken]) revert InvalidPaymentToken();
    }
}