// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@dcl/common-contracts/meta-transactions/NativeMetaTransaction.sol";
import "@dcl/common-contracts/signatures/ContractIndexVerifiable.sol";
import "@dcl/common-contracts/signatures/SignerIndexVerifiable.sol";
import "@dcl/common-contracts/signatures/AssetIndexVerifiable.sol";

import "./interfaces/IERC721Rentable.sol";

contract Rentals is
    ContractIndexVerifiable,
    SignerIndexVerifiable,
    AssetIndexVerifiable,
    NativeMetaTransaction,
    IERC721Receiver,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /// @dev EIP712 type hashes for recovering the signer from a signature.
    bytes32 private constant LISTING_TYPE_HASH =
        keccak256(
            bytes(
                "Listing(address signer,address contractAddress,uint256 tokenId,uint256 expiration,uint256[3] indexes,uint256[] pricePerDay,uint256[] maxDays,uint256[] minDays,address target)"
            )
        );

    bytes32 private constant OFFER_TYPE_HASH =
        keccak256(
            bytes(
                "Offer(address signer,address contractAddress,uint256 tokenId,uint256 expiration,uint256[3] indexes,uint256 pricePerDay,uint256 rentalDays,address operator,bytes32 fingerprint)"
            )
        );

    uint256 private constant MAX_FEE = 1_000_000;
    uint256 private constant MAX_RENTAL_DAYS = 36525; // 100 years

    /// @dev EIP165 hash used to detect if a contract supports the verifyFingerprint(uint256,bytes) function.
    bytes4 private constant InterfaceId_VerifyFingerprint = bytes4(keccak256("verifyFingerprint(uint256,bytes)"));

    /// @dev EIP165 hash used to detect if a contract supports the onERC721Received(address,address,uint256,bytes) function.
    bytes4 private constant InterfaceId_OnERC721Received = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @notice ERC20 token used to pay for rent and fees.
    IERC20 private token;

    /// @notice Tracks necessary rental data per asset.
    /// @custom:schema (contract address -> token id -> rental)
    mapping(address => mapping(uint256 => Rental)) internal rentals;

    /// @notice Address that will receive ERC20 tokens collected as rental fees.
    address private feeCollector;

    /// @notice Value per million wei that will be deducted from the rental price and sent to the collector.
    uint256 private fee;

    /// @notice Struct received as a parameter in `acceptListing` containing all information about
    /// listing conditions and values required to verify that the signature was created by the signer.
    struct Listing {
        address signer;
        address contractAddress;
        uint256 tokenId;
        uint256 expiration;
        uint256[3] indexes;
        uint256[] pricePerDay;
        uint256[] maxDays;
        uint256[] minDays;
        // Makes the listing acceptable only by the address defined as target.
        // Using address(0) as target will allow any address to accept it.
        address target;
        bytes signature;
    }

    /// @notice Struct received as a parameter in `acceptOffer` or as _data parameter in onERC721Received
    /// containing all information about offer conditions and values required to verify that the signature was created by the signer.
    struct Offer {
        address signer;
        address contractAddress;
        uint256 tokenId;
        uint256 expiration;
        uint256[3] indexes;
        uint256 pricePerDay;
        uint256 rentalDays;
        address operator;
        bytes32 fingerprint;
        bytes signature;
    }

    /// @notice Info stored in the rentals mapping to track rental information.
    struct Rental {
        address lessor;
        address tenant;
        uint256 endDate;
    }

    /// @dev Used internally as an argument of the _rent function as an alternative to passing a long list
    /// of arguments.
    struct RentParams {
        address lessor;
        address tenant;
        address contractAddress;
        uint256 tokenId;
        bytes32 fingerprint;
        uint256 pricePerDay;
        uint256 rentalDays;
        address operator;
        bytes signature;
    }

    event FeeCollectorUpdated(address _from, address _to, address _sender);
    event FeeUpdated(uint256 _from, uint256 _to, address _sender);
    event AssetClaimed(address indexed _contractAddress, uint256 indexed _tokenId, address _sender);
    event AssetRented(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address _lessor,
        address _tenant,
        address _operator,
        uint256 _rentalDays,
        uint256 _pricePerDay,
        bool _isExtension,
        address _sender,
        bytes _signature
    );

    constructor() {
        // Prevents the implementation to be initialized.
        // Initialization can only be done through a Proxy.
        _disableInitializers();
    }

    /// @notice Initialize the contract.
    /// @dev This method should be called as soon as the contract is deployed.
    /// Using this method in favor of a constructor allows the implementation of various kinds of proxies.
    /// @param _owner The address of the owner of the contract.
    /// @param _token The address of the ERC20 token used by tenants to pay rent.
    /// This token is set once on initialization and cannot be changed afterwards.
    /// @param _feeCollector Address that will receive rental fees
    /// @param _fee Value per million wei that will be transferred from the rental price to the fee collector.
    function initialize(
        address _owner,
        IERC20 _token,
        address _feeCollector,
        uint256 _fee
    ) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __NativeMetaTransaction_init("Rentals", "1");
        __ContractIndexVerifiable_init();
        _transferOwnership(_owner);
        _setFeeCollector(_feeCollector);
        _setFee(_fee);

        token = _token;
    }

    /// @notice Pause the contract and prevent core functions from being called.
    /// Functions that will be paused are:
    /// - acceptListing
    /// - acceptOffer
    /// - onERC721Received (No offers will be accepted through a safeTransfer to this contract)
    /// - claim
    /// - setUpdateOperator
    /// - setManyLandUpdateOperator
    /// @dev The contract has to be unpaused or this function will revert.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resume the normal functionality of the contract.
    /// @dev The contract has to be paused or this function will revert.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the rental data for a given asset.
    /// @param _contractAddress The contract address of the asset.
    /// @param _tokenId The id of the asset.
    function getRental(address _contractAddress, uint256 _tokenId) external view returns (Rental memory) {
        return rentals[_contractAddress][_tokenId];
    }

    /// @notice Get the current token address used for rental payments.
    /// @return The address of the token.
    function getToken() external view returns (IERC20) {
        return token;
    }

    /// @notice Get the current address that will receive a cut of rental payments as a fee.
    /// @return The address of the fee collector.
    function getFeeCollector() external view returns (address) {
        return feeCollector;
    }

    /// @notice Get the value per MAX_FEE that will be cut from the rental payment and sent to the fee collector.
    /// @return The value of the current fee.
    function getFee() external view returns (uint256) {
        return fee;
    }

    /// @notice Get if an asset is currently being rented.
    /// @param _contractAddress The contract address of the asset.
    /// @param _tokenId The token id of the asset.
    /// @return True or false depending if the asset is currently rented.
    function getIsRented(address _contractAddress, uint256 _tokenId) public view returns (bool) {
        return block.timestamp <= rentals[_contractAddress][_tokenId].endDate;
    }

    /// @notice Set the address of the fee collector.
    /// @param _feeCollector The address of the fee collector.
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /// @notice Set the fee (per million wei) for rentals.
    /// @param _fee The value for the fee.
    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    /// @notice Accept a rental listing created by the owner of an asset.
    /// @param _listing Contains the listing conditions as well as the signature data for verification.
    /// @param _operator The address that will be given operator permissions over an asset.
    /// @param _conditionIndex The rental conditions index chosen from the options provided in _listing.
    /// @param _rentalDays The amount of days the caller wants to rent the asset.
    /// Must be a value between the selected condition's min and max days.
    /// @param _fingerprint The fingerprint used to verify composable erc721s.
    /// Useful in order to prevent a front run were, for example, the owner removes LAND from an Estate before
    /// the listing is accepted. Causing the tenant to end up with an Estate that does not have the amount of LAND
    /// they expect.
    function acceptListing(
        Listing calldata _listing,
        address _operator,
        uint256 _conditionIndex,
        uint256 _rentalDays,
        bytes32 _fingerprint
    ) external nonReentrant whenNotPaused {
        _verifyUnsafeTransfer(_listing.contractAddress, _listing.tokenId);

        address lessor = _listing.signer;
        address tenant = _msgSender();

        // Verify that the caller and the signer are not the same address.
        require(tenant != lessor, "Rentals#acceptListing: CALLER_CANNOT_BE_SIGNER");

        // Verify that the targeted address in the listing, if not address(0), is the caller of this function.
        require(_listing.target == address(0) || _listing.target == tenant, "Rentals#acceptListing: TARGET_MISMATCH");

        // Verify that the indexes provided in the listing match the ones in the contract.
        _verifyContractIndex(_listing.indexes[0]);
        _verifySignerIndex(lessor, _listing.indexes[1]);
        _verifyAssetIndex(_listing.contractAddress, _listing.tokenId, lessor, _listing.indexes[2]);

        uint256 pricePerDayLength = _listing.pricePerDay.length;

        // Verify that pricePerDay, maxDays and minDays have the same length
        require(pricePerDayLength == _listing.maxDays.length, "Rentals#acceptListing: MAX_DAYS_LENGTH_MISMATCH");
        require(pricePerDayLength == _listing.minDays.length, "Rentals#acceptListing: MIN_DAYS_LENGTH_MISMATCH");

        // Verify that the provided condition index is not out of bounds of the listing conditions.
        require(_conditionIndex < pricePerDayLength, "Rentals#acceptListing: CONDITION_INDEX_OUT_OF_BOUNDS");

        // Verify that the listing is not already expired.
        require(_listing.expiration >= block.timestamp, "Rentals#acceptListing: EXPIRED_SIGNATURE");

        uint256 maxDays = _listing.maxDays[_conditionIndex];
        uint256 minDays = _listing.minDays[_conditionIndex];

        // Verify that minDays and maxDays have valid values.
        require(minDays <= maxDays, "Rentals#acceptListing: MAX_DAYS_LOWER_THAN_MIN_DAYS");
        require(minDays > 0, "Rentals#acceptListing: MIN_DAYS_IS_ZERO");

        // Verify that the provided rental days is between min and max days range.
        require(_rentalDays >= minDays && _rentalDays <= maxDays, "Rentals#acceptListing: DAYS_NOT_IN_RANGE");

        // Verify that the provided rental days does not exceed MAX_RENTAL_DAYS
        require(_rentalDays <= MAX_RENTAL_DAYS, "Rentals#acceptListing: RENTAL_DAYS_EXCEEDS_LIMIT");

        _verifyListingSigner(_listing);

        _rent(
            RentParams(
                lessor,
                tenant,
                _listing.contractAddress,
                _listing.tokenId,
                _fingerprint,
                _listing.pricePerDay[_conditionIndex],
                _rentalDays,
                _operator,
                _listing.signature
            )
        );
    }

    /// @notice Accept an offer for rent of an asset owned by the caller.
    /// @param _offer Contains the offer conditions as well as the signature data for verification.
    function acceptOffer(Offer calldata _offer) external {
        _verifyUnsafeTransfer(_offer.contractAddress, _offer.tokenId);

        _acceptOffer(_offer, _msgSender());
    }

    /// @notice The original owner of the asset can claim it back if said asset is not being rented.
    /// @param _contractAddresses The contract address of the assets to be claimed.
    /// @param _tokenIds The token ids of the assets to be claimed.
    /// Each tokenId corresponds to a contract address in the same index.
    function claim(address[] calldata _contractAddresses, uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        require(_contractAddresses.length == _tokenIds.length, "Rentals#claim: LENGTH_MISMATCH");

        address sender = _msgSender();

        uint256 contractAddressesLength = _contractAddresses.length;

        for (uint256 i; i < contractAddressesLength; ) {
            address contractAddress = _contractAddresses[i];
            uint256 tokenId = _tokenIds[i];

            // Verify that the rent has finished.
            require(!getIsRented(contractAddress, tokenId), "Rentals#claim: CURRENTLY_RENTED");

            address lessor = rentals[contractAddress][tokenId].lessor;

            // Verify that the caller is the original owner of the asset.
            require(lessor == sender, "Rentals#claim: NOT_LESSOR");

            // Delete the data for the rental as it is not necessary anymore.
            delete rentals[contractAddress][tokenId];

            // Transfer the asset back to its original owner.
            IERC721Rentable asset = IERC721Rentable(contractAddress);

            asset.safeTransferFrom(address(this), sender, tokenId);

            emit AssetClaimed(contractAddress, tokenId, sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the update operator of the provided assets.
    /// @dev Only when the rent is active a tenant can change the operator of an asset.
    /// When the rent is over, the lessor is the one that can change operators.
    /// In the case of the lessor, this is useful to update the operator without having to claim the asset back once the rent is over.
    /// Elements in the param arrays correspond to each other in the same index.
    /// For example, asset with address _contractAddresses[0] and token id _tokenIds[0] will be set _operators[0] as operator.
    /// @param _contractAddresses The contract addresses of the assets.
    /// @param _tokenIds The token ids of the assets.
    /// @param _operators The addresses that will have operator privileges over the given assets in the same index.
    function setUpdateOperator(
        address[] calldata _contractAddresses,
        uint256[] calldata _tokenIds,
        address[] calldata _operators
    ) external nonReentrant whenNotPaused {
        require(
            _contractAddresses.length == _tokenIds.length && _contractAddresses.length == _operators.length,
            "Rentals#setUpdateOperator: LENGTH_MISMATCH"
        );

        address sender = _msgSender();

        uint256 tokenIdsLength = _tokenIds.length;

        for (uint256 i; i < tokenIdsLength; ) {
            address contractAddress = _contractAddresses[i];
            uint256 tokenId = _tokenIds[i];
            Rental storage rental = rentals[contractAddress][tokenId];
            bool isRented = getIsRented(contractAddress, tokenId);

            require(
                (isRented && sender == rental.tenant) || (!isRented && sender == rental.lessor),
                "Rentals#setUpdateOperator: CANNOT_SET_UPDATE_OPERATOR"
            );

            IERC721Rentable(contractAddress).setUpdateOperator(tokenId, _operators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the operator of individual LANDs inside an Estate
    /// @dev LAND inside an Estate can be granularly given update operator permissions by calling the setLandUpdateOperator
    /// (or setManyLandUpdateOperator) in the Estate contract.
    /// All update operators defined like this will remain after the Estate is rented because they are not cleared up on transfer.
    /// To prevent these remaining update operators from being able to deploy and override scenes from the current tenant, the tenant
    /// can call this function to clear or override them.
    /// The lessor can do the same after the rental is over to clear up any individual LAND update operators set by the tenant.
    /// @param _contractAddress The address of the Estate contract containing the LANDs that will have their update operators updated.
    /// @param _tokenId The Estate id.
    /// @param _landTokenIds An array of LAND token id arrays which will have the update operator updated. Each array corresponds to the operator of the same index.
    /// @param _operators An array of addresses that will be set as update operators of the provided LAND token ids.
    function setManyLandUpdateOperator(
        address _contractAddress,
        uint256 _tokenId,
        uint256[][] calldata _landTokenIds,
        address[] calldata _operators
    ) external nonReentrant whenNotPaused {
        require(_landTokenIds.length == _operators.length, "Rentals#setManyLandUpdateOperator: LENGTH_MISMATCH");

        Rental storage rental = rentals[_contractAddress][_tokenId];
        bool isRented = getIsRented(_contractAddress, _tokenId);
        address sender = _msgSender();

        require(
            (isRented && sender == rental.tenant) || (!isRented && sender == rental.lessor),
            "Rentals#setManyLandUpdateOperator: CANNOT_SET_MANY_LAND_UPDATE_OPERATOR"
        );

        uint256 landTokenIdsLength = _landTokenIds.length;

        for (uint256 i; i < landTokenIdsLength; ) {
            IERC721Rentable(_contractAddress).setManyLandUpdateOperator(_tokenId, _landTokenIds[i], _operators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Standard function called by ERC721 contracts whenever a safe transfer occurs.
    /// Provides an alternative to acceptOffer by letting the asset holder send the asset to the contract
    /// and accepting the offer at the same time.
    /// IMPORTANT: Addresses (Not necessarily EOA but contracts as well) that have been given allowance to an asset can safely transfer said asset to this contract
    /// to accept an offer. The address that has been given allowance will be considered the lessor, and will enjoy all of its benefits,
    /// including the ability to claim the asset back to themselves after the rental period is over.
    /// @param _operator Caller of the safeTransfer function.
    /// @param _tokenId Id of the asset received.
    /// @param _data Bytes containing offer data.
    function onERC721Received(
        address _operator,
        address, // _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (_operator != address(this)) {
            Offer memory offer = abi.decode(_data, (Offer));

            // Check that the caller is the contract defined in the offer to ensure the function is being
            // called through an ERC721.safeTransferFrom.
            // Also check that the token id is the same as the one provided in the offer.
            require(msg.sender == offer.contractAddress && offer.tokenId == _tokenId, "Rentals#onERC721Received: ASSET_MISMATCH");

            _acceptOffer(offer, _operator);
        }

        return InterfaceId_OnERC721Received;
    }

    /// @dev Overriding to return NativeMetaTransaction._getMsgSender for the contract to support meta transactions.
    function _msgSender() internal view override returns (address) {
        return _getMsgSender();
    }

    function _setFeeCollector(address _feeCollector) private {
        emit FeeCollectorUpdated(feeCollector, feeCollector = _feeCollector, _msgSender());
    }

    function _setFee(uint256 _fee) private {
        require(_fee <= MAX_FEE, "Rentals#_setFee: HIGHER_THAN_MAX_FEE");

        emit FeeUpdated(fee, fee = _fee, _msgSender());
    }

    /// @dev Someone might send an asset to this contract via an unsafe transfer, causing ownerOf checks to be inconsistent with the state
    /// of this contract. This function is used to prevent interactions with these assets.
    /// ERC721 ASSETS SENT UNSAFELY WILL REMAIN LOCKED INSIDE THIS CONTRACT.
    function _verifyUnsafeTransfer(address _contractAddress, uint256 _tokenId) private view {
        address lessor = rentals[_contractAddress][_tokenId].lessor;
        address assetOwner = IERC721Rentable(_contractAddress).ownerOf(_tokenId);

        if (lessor == address(0) && assetOwner == address(this)) {
            revert("Rentals#_verifyUnsafeTransfer: ASSET_TRANSFERRED_UNSAFELY");
        }
    }

    function _acceptOffer(Offer memory _offer, address _lessor) private nonReentrant whenNotPaused {
        address tenant = _offer.signer;

        // Verify that the caller and the signer are not the same address.
        require(_lessor != tenant, "Rentals#_acceptOffer: CALLER_CANNOT_BE_SIGNER");

        // Verify that the indexes provided in the offer match the ones in the contract.
        _verifyContractIndex(_offer.indexes[0]);
        _verifySignerIndex(tenant, _offer.indexes[1]);
        _verifyAssetIndex(_offer.contractAddress, _offer.tokenId, tenant, _offer.indexes[2]);

        // Verify that the offer is not already expired.
        require(_offer.expiration >= block.timestamp, "Rentals#_acceptOffer: EXPIRED_SIGNATURE");

        // Verify that the rental days provided in the offer are valid.
        require(_offer.rentalDays > 0, "Rentals#_acceptOffer: RENTAL_DAYS_IS_ZERO");

        // Verify that the provided rental days does not exceed MAX_RENTAL_DAYS
        require(_offer.rentalDays <= MAX_RENTAL_DAYS, "Rentals#_acceptOffer: RENTAL_DAYS_EXCEEDS_LIMIT");

        _verifyOfferSigner(_offer);

        _rent(
            RentParams(
                _lessor,
                tenant,
                _offer.contractAddress,
                _offer.tokenId,
                _offer.fingerprint,
                _offer.pricePerDay,
                _offer.rentalDays,
                _offer.operator,
                _offer.signature
            )
        );
    }

    /// @dev Verify that the signer provided in the listing is the address that created the provided signature.
    function _verifyListingSigner(Listing calldata _listing) private view {
        address listingSigner = _listing.signer;

        bytes32 listingHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LISTING_TYPE_HASH,
                    listingSigner,
                    _listing.contractAddress,
                    _listing.tokenId,
                    _listing.expiration,
                    keccak256(abi.encodePacked(_listing.indexes)),
                    keccak256(abi.encodePacked(_listing.pricePerDay)),
                    keccak256(abi.encodePacked(_listing.maxDays)),
                    keccak256(abi.encodePacked(_listing.minDays)),
                    _listing.target
                )
            )
        );

        _verifySigner(listingSigner, listingHash, _listing.signature);
    }

    /// @dev Verify that the signer provided in the offer is the address that created the provided signature.
    function _verifyOfferSigner(Offer memory _offer) private view {
        address offerSigner = _offer.signer;

        bytes32 offerHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    OFFER_TYPE_HASH,
                    offerSigner,
                    _offer.contractAddress,
                    _offer.tokenId,
                    _offer.expiration,
                    keccak256(abi.encodePacked(_offer.indexes)),
                    _offer.pricePerDay,
                    _offer.rentalDays,
                    _offer.operator,
                    _offer.fingerprint
                )
            )
        );

        _verifySigner(offerSigner, offerHash, _offer.signature);
    }

    /// @dev Verify that the signature is valid for the provided signer and hash.
    /// Will perform an ecrecover for EOA _signers and ERC1271 verification for contract _signers.
    function _verifySigner(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) private view {
        if (_signer.code.length == 0) {
            require(_signer == ECDSAUpgradeable.recover(_hash, _signature), "Rentals#_verifySigner: SIGNER_MISMATCH");
        } else {
            require(
                IERC1271.isValidSignature.selector == IERC1271(_signer).isValidSignature(_hash, _signature),
                "Rentals#_verifySigner: MAGIC_VALUE_MISMATCH"
            );
        }
    }

    function _rent(RentParams memory _rentParams) private {
        IERC721Rentable asset = IERC721Rentable(_rentParams.contractAddress);

        // If the provided contract supports the verifyFingerprint function, validate the provided fingerprint.
        if (asset.supportsInterface(InterfaceId_VerifyFingerprint)) {
            require(asset.verifyFingerprint(_rentParams.tokenId, abi.encode(_rentParams.fingerprint)), "Rentals#_rent: INVALID_FINGERPRINT");
        }

        Rental storage rental = rentals[_rentParams.contractAddress][_rentParams.tokenId];

        // True if the asset is currently rented.
        bool isRented = getIsRented(_rentParams.contractAddress, _rentParams.tokenId);
        // True if the asset rental period is over, but is has not been claimed back from the contract.
        bool isReRent = !isRented && rental.lessor != address(0);
        // True if the asset rental period is not over yet, but the lessor and the tenant are the same.
        bool isExtend = isRented && rental.lessor == _rentParams.lessor && rental.tenant == _rentParams.tenant;

        if (!isExtend && !isReRent) {
            // Verify that the asset is not already rented.
            require(!isRented, "Rentals#_rent: CURRENTLY_RENTED");
        }

        if (isReRent) {
            // The asset is being rented again without claiming it back first, so we need to check that the previous lessor
            // is the same as the lessor this time to prevent anyone else from acting as the lessor.
            require(rental.lessor == _rentParams.lessor, "Rentals#_rent: NOT_ORIGINAL_OWNER");
        }

        if (isExtend) {
            // Increase the current end date by the amount of provided rental days.
            rental.endDate = rental.endDate + _rentParams.rentalDays * 1 days;
        } else {
            // Track the original owner of the asset in the lessors map for future use.
            rental.lessor = _rentParams.lessor;

            // Track the new tenant in the mapping.
            rental.tenant = _rentParams.tenant;

            // Set the end date of the rental according to the provided rental days
            rental.endDate = block.timestamp + _rentParams.rentalDays * 1 days;
        }

        // Update the asset indexes for both the lessor and the tenant to invalidate old signatures.
        _bumpAssetIndex(_rentParams.contractAddress, _rentParams.tokenId, _rentParams.lessor);
        _bumpAssetIndex(_rentParams.contractAddress, _rentParams.tokenId, _rentParams.tenant);

        // Transfer tokens
        if (_rentParams.pricePerDay > 0) {
            _handleTokenTransfers(_rentParams.lessor, _rentParams.tenant, _rentParams.pricePerDay, _rentParams.rentalDays);
        }

        // Only transfer the ERC721 to this contract if it doesn't already have it.
        if (asset.ownerOf(_rentParams.tokenId) != address(this)) {
            asset.safeTransferFrom(_rentParams.lessor, address(this), _rentParams.tokenId);
        }

        // Update the operator
        asset.setUpdateOperator(_rentParams.tokenId, _rentParams.operator);

        emit AssetRented(
            _rentParams.contractAddress,
            _rentParams.tokenId,
            _rentParams.lessor,
            _rentParams.tenant,
            _rentParams.operator,
            _rentParams.rentalDays,
            _rentParams.pricePerDay,
            isExtend,
            _msgSender(),
            _rentParams.signature
        );
    }

    /// @dev Transfer the erc20 tokens required to start a rent from the tenant to the lessor and the fee collector.
    function _handleTokenTransfers(
        address _lessor,
        address _tenant,
        uint256 _pricePerDay,
        uint256 _rentalDays
    ) private {
        uint256 totalPrice = _pricePerDay * _rentalDays;
        uint256 forCollector = (totalPrice * fee) / MAX_FEE;

        // Save the reference in memory so it doesn't access storage twice.
        IERC20 mToken = token;

        // Transfer the rental payment to the lessor minus the fee which is transferred to the collector.
        mToken.transferFrom(_tenant, _lessor, totalPrice - forCollector);
        mToken.transferFrom(_tenant, feeCollector, forCollector);
    }
}