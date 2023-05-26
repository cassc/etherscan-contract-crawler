pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {ERC721KODACreator} from "../ERC721KODACreator.sol";
import {IERC721KODACreatorWithBuyItNow} from "../interfaces/IERC721KODACreatorWithBuyItNow.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
/// @notice ERC721 KODA Creator with Embedded Primary and Secondary Buy It Now Marketplace
contract ERC721KODACreatorWithBuyItNow is
    ERC721KODACreator,
    IERC721KODACreatorWithBuyItNow
{
    /// @notice Edition ID -> Listing Metadata
    mapping(uint256 => EditionListing) public editionListing;

    /// @notice Token ID -> Owner Address -> Listing Metadata
    mapping(uint256 => mapping(address => TokenListing)) public tokenListing;

    // ********** //
    // * PUBLIC * //
    // ********** //

    /// @inheritdoc ERC721KODACreator
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return
            interfaceId == type(IERC721KODACreatorWithBuyItNow).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // * Marketplace * //

    /**
     * @notice Buy Edition Token
     * @dev allows the purchase of the next available token for sale from an edition listing
     *
     * Requirements:
     *
     * - the listing must exist
     * - the value sent must be equal to the listing price
     * - the listing must be active i.e. the current time must be after the listing start time
     *
     * @param _editionId the ID of the edition to purchase a token from
     * @param _recipient the address that should receive the token purchased
     */
    function buyEditionToken(
        uint256 _editionId,
        address _recipient
    ) external payable override whenNotPaused nonReentrant {
        EditionListing storage listing = editionListing[_editionId];
        if (listing.price == 0) revert InvalidListing();
        if (msg.value != listing.price) revert InvalidPrice();
        if (block.timestamp < listing.startDate) revert TooEarly();
        if (listing.endDate > 0 && block.timestamp > listing.endDate)
            revert TooLate();

        // when owner has renounced ownership, then the transfer will fail but nicer to fail early
        address _owner = owner();
        if (_owner == address(0)) revert EditionSalesDisabled();

        // get the next token ID
        uint256 tokenId = _facilitateNextPrimarySale(_editionId, _recipient);

        address platform = kodaSettings.platform();
        uint256 primaryPercentageForPlatform = kodaSettings
            .platformPrimaryCommission();
        uint256 platformProceeds = (msg.value * primaryPercentageForPlatform) /
            MODULO;

        // Where platform primary commission is zero from the settings, we don't need to execute the transaction
        bool success;
        if (platformProceeds > 0) {
            (success, ) = platform.call{value: platformProceeds}("");
            if (!success) revert TransferFailed();
        }

        // send all the funds to the handler - KO is part of this
        (success, ) = editionFundsHandler(_editionId).call{
            value: msg.value - platformProceeds
        }("");
        if (!success) revert TransferFailed();

        emit BuyNowPurchased(tokenId, msg.sender, _owner, listing.price);
    }

    /**
     * @notice List a Token for sale
     * @dev allows the owner of a token to create a secondary buy it now listing
     * @param _tokenId the ID of the token to list for sale
     * @param _listingPrice the price to list the token for
     * @param _startDate the time the listing is enabled
     * @param _endDate the time the listing is disabled
     */
    function createTokenBuyItNowListing(
        uint256 _tokenId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) external override {
        if (_owners[_tokenId] != msg.sender) revert InvalidToken();
        if (_listingPrice == 0) revert InvalidPrice();
        if (tokenListing[_tokenId][msg.sender].price != 0)
            revert AlreadyListed();

        // Store listing data
        tokenListing[_tokenId][msg.sender] = TokenListing(
            msg.sender,
            _listingPrice
        );

        emit ListedTokenForBuyNow(
            msg.sender,
            _tokenId,
            _listingPrice,
            _startDate,
            _endDate
        );
    }

    /**
     * @notice Delist a Token for Sale
     * @dev allows the owner of a token to remove a listing for the token
     * @param _tokenId the ID of the token to delist
     */
    function deleteTokenBuyItNowListing(uint256 _tokenId) external override {
        if (tokenListing[_tokenId][msg.sender].price == 0)
            revert InvalidListing();

        delete tokenListing[_tokenId][msg.sender];

        emit BuyNowTokenDeListed(_tokenId);
    }

    /**
     * @notice Update Token Listing Price
     * @dev allows the owner of a token to update the price
     * @param _tokenId the ID of the token already listed
     * @param _listingPrice the new listing price to set
     */
    function updateTokenBuyItNowListingPrice(
        uint256 _tokenId,
        uint96 _listingPrice
    ) external override {
        if (tokenListing[_tokenId][msg.sender].price == 0)
            revert InvalidListing();
        if (ownerOf(_tokenId) != msg.sender) revert InvalidListing();
        if (_listingPrice == 0) revert InvalidPrice();

        tokenListing[_tokenId][msg.sender].price = _listingPrice;

        emit BuyNowTokenPriceChanged(_tokenId, _listingPrice);
    }

    /**
     * @notice Buy Token
     * @dev allows the purchase of a token listed for sale
     *
     * Requirements:
     *
     * - the listing must exist
     * - the value sent must be equal to the listing price
     *
     * @param _tokenId the ID of the token to purchase
     * @param _recipient the address that should receive the token purchased
     */
    function buyToken(
        uint256 _tokenId,
        address _recipient
    ) external payable override nonReentrant {
        TokenListing storage listing = tokenListing[_tokenId][
            ownerOf(_tokenId)
        ];
        if (listing.price == 0) revert InvalidListing();
        if (listing.price != msg.value) revert InvalidPrice();

        // calculate proceeds owed to platform, creator and seller
        address platform = kodaSettings.platform();
        uint256 secondaryPercentageForPlatform = kodaSettings
            .platformSecondaryCommission();

        uint256 platformProceeds = (msg.value *
            secondaryPercentageForPlatform) / MODULO;
        (address receiver, uint256 royaltyAmount) = royaltyInfo(
            _tokenId,
            msg.value
        );

        // Where platform proceeds is zero due to the settings, no need to call the transfer
        bool success;
        if (platformProceeds > 0) {
            (success, ) = platform.call{value: platformProceeds}("");
            if (!success) revert TransferFailed();
        }

        if (royaltyAmount > 0) {
            (success, ) = receiver.call{value: royaltyAmount}("");
            if (!success) revert TransferFailed();
        }

        // maximum platform commission and royalty percentage are both limited to 50% (max 100% of sale value total)
        // it is also extremely unlikely that they will ever both use the max so no need for additional validation/conditions
        (success, ) = listing.seller.call{
            value: msg.value - royaltyAmount - platformProceeds
        }("");
        if (!success) revert TransferFailed();

        emit BuyNowTokenPurchased(
            _tokenId,
            msg.sender,
            _recipient,
            listing.seller,
            listing.price
        );

        ERC721KODACreatorWithBuyItNow(address(this)).transferFrom(
            listing.seller,
            _recipient,
            _tokenId
        );

        delete tokenListing[_tokenId][ownerOf(_tokenId)];
    }

    /**
     * @notice Get the token listing details for the current token owner
     * @dev Get a token listing just from token ID and not worrying about current owner
     * @param _tokenId the ID of the token
     * @return TokenListing details of the token listing
     */
    function getTokenListing(
        uint256 _tokenId
    ) external view returns (TokenListing memory) {
        return tokenListing[_tokenId][ownerOf(_tokenId)];
    }

    // ********* //
    // * OWNER * //
    // ********* //

    // * Editions * //

    /**
     * @notice List and Edition for Buy It Now
     * @dev allows the edition owner to create a listing to enable sales of tokens from an edition
     *
     * @param _editionId the ID of the edition to create a listing for
     * @param _listingPrice the price to list for
     * @param _startDate the time that the listing becomes active
     * @param _endDate the time the listing is disabled
     */
    function createEditionBuyItNowListing(
        uint256 _editionId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) public override onlyEditionOwner(_editionId) {
        _createEditionBuyItNowListing(
            _editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
    }

    /**
     * @notice Delist an Edition for Sale
     * @param _editionId the ID of the edition to delist
     */
    function deleteEditionBuyItNowListing(
        uint256 _editionId
    ) external override onlyEditionOwner(_editionId) {
        if (editionListing[_editionId].price == 0) revert EditionNotListed();
        delete editionListing[_editionId];
        emit BuyNowDeListed(_editionId);
    }

    /**
     * @notice Create and Mint an Edition and List it for Sale
     * @dev allows the contract owner to create a pre-minted edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @param _uri the metadata URI of the edition
     * @return uint256 the ID of the new edition created
     */
    function mintAndListEditionForBuyNow(
        uint32 _editionSize,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        string calldata _uri
    ) external onlyOwner returns (uint256) {
        // Creator override only required if there are sub-minters in addition to contract owner
        uint256 editionId = _createEdition(
            _editionSize,
            _editionSize,
            owner(),
            address(0),
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /**
     * @notice Create and Mint an Edition and List it for Sale
     * @dev allows the contract owner to create a pre-minted edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @param _collabFundsHandler the fund splitting contract
     * @param _uri the metadata URI of the edition
     * @return uint256 the ID of the new edition created
     */
    function mintAndListEditionAsCollaborationForBuyNow(
        uint32 _editionSize,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        address _collabFundsHandler,
        string calldata _uri
    ) external onlyOwner returns (uint256) {
        // Creator override only required if there are sub-minters in addition to contract owner
        uint256 editionId = createEditionAsCollaboration(
            _editionSize,
            _editionSize,
            owner(),
            address(0),
            _collabFundsHandler,
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /// @notice Setup the open edition template and list for buy it now
    /**
     * @notice Create an Open Edition and List it for Sale
     * @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _uri the metadata URI of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @return uint256 the ID of the new edition created
     */
    function setupAndListOpenEdition(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _editionSize
    ) external override onlyOwner returns (uint256) {
        uint256 editionId = _createEdition(
            _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
            0,
            owner(),
            address(0),
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /// @notice Setup the open edition template and list for buy it now
    /**
     * @notice Create an Open Edition and List it for Sale
     * @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _uri the metadata URI of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @return uint256 the ID of the new edition created
     * @param _collabFundsHandler the fund splitting contract
     */
    function setupAndListOpenEditionAsCollaboration(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _editionSize,
        address _collabFundsHandler
    ) external onlyOwner returns (uint256) {
        uint256 editionId = createOpenEditionAsCollaboration(
            _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
            _collabFundsHandler,
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /**
     * @notice Update Edition Listing Price
     * @dev allows the contract owner to update the price of edition tokens listed for sale
     * @param _editionId the ID of the edition already listed
     * @param _listingPrice the new listing price to set
     */
    function updateEditionBuyItNowListingPrice(
        uint256 _editionId,
        uint96 _listingPrice
    ) external override onlyEditionOwner(_editionId) {
        if (editionListing[_editionId].price == 0) revert EditionNotListed();
        if (_listingPrice == 0) revert InvalidPrice();

        // Set price
        editionListing[_editionId].price = _listingPrice;

        // Emit event
        emit BuyNowPriceChanged(_editionId, _listingPrice);
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    /**
     * @dev create a listing to enable sales of tokens from an edition
     *
     * Requirements:
     *
     * - Should have owner validation in parent function
     * - The edition exists
     * - A listing does not already exist for the edition
     * - The listing price is not less than the global minimum
     *
     * @param _editionId the ID of the edition to create a listing for
     * @param _listingPrice the price to list for
     * @param _startDate the time that the listing becomes active
     * @param _endDate the time the listing is disabled
     */
    function _createEditionBuyItNowListing(
        uint256 _editionId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) internal {
        if (editionListing[_editionId].price != 0) revert AlreadyListed();
        if (_listingPrice == 0) revert InvalidPrice();

        // automatically set approval for the contract against the edition owner if not already set
        // this is so do they do not need to do it manually in order to sell any editions they list
        if (!_operatorApprovals[msg.sender][address(this)]) {
            _operatorApprovals[msg.sender][address(this)] = true;
            emit ApprovalForAll(msg.sender, address(this), true);
        }

        // Store listing data
        editionListing[_editionId] = EditionListing(
            _listingPrice,
            _startDate,
            _endDate
        );

        emit ListedEditionForBuyNow(_editionId, _listingPrice, _startDate);
    }
}