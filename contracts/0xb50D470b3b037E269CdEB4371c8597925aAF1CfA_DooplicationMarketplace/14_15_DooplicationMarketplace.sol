// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IDooplication.sol";

contract DooplicationMarketplace is
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");

    // Map (dooplicationContract => tokenContract => tokenId => Listing).
    // Track listings per dooplication and token contracts
    mapping(address => mapping(address => mapping(uint256 => Listing)))
        private _listings;

    // Map (dooplicationContract => tokenContract => UintSet).
    // Track tokenId of listings per dooplication and token contracts
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private _listingTokenIdSets;

    // Map (dooplicationContract => active). Track active dooplication contracts
    mapping(address => bool) private _activeDooplications;

    // Map (tokenContract => TokenRoyalty). Track royalties per token contract
    mapping(address => TokenRoyalty) private _tokenRoyalties;

    struct ListingView {
        uint256 tokenId;
        Listing listing;
        bool dooplicable;
    }

    struct Listing {
        uint256 price;
        uint256 postDate;
        address seller;
    }

    struct TokenRoyalty {
        bool enabled;
        address receiver;
        uint88 royaltyFraction;
    }

    event ItemListed(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address dooplicationAddress,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address dooplicationAddress
    );

    event ItemDooplicated(
        address indexed buyer,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address dooplicationAddress,
        uint256 price
    );

    error PriceNotMet(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );
    error NotListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    );
    error AlreadyListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    );
    error NotOwner();
    error PriceMustBeAboveZero();
    error IsOwner();
    error DooplicationContractNotActive(address dooplicationContract);
    error TokenContractNotApproved(
        address dooplicationContract,
        address tokenAddress
    );
    error TokenContractNotActive(
        address dooplicationContract,
        address tokenAddress
    );
    error InvalidRoyaltyFraction();
    error InvalidRoyaltyReceiver();
    error TokenHasBeenDooplicated(
        address dooplicationContract,
        address tokenAddress,
        uint256 tokenId
    );

    modifier notListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) {
        Listing memory listing = _listings[dooplicationAddress][tokenAddress][
            tokenId
        ];
        if (listing.price > 0) {
            if (listing.seller == IERC721(tokenAddress).ownerOf(tokenId)) {
                revert AlreadyListed(
                    dooplicationAddress,
                    tokenAddress,
                    tokenId
                );
            }
        }
        _;
    }

    modifier isListed(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) {
        Listing memory listing = _listings[dooplicationAddress][tokenAddress][
            tokenId
        ];
        if (
            listing.price == 0 ||
            listing.seller != IERC721(tokenAddress).ownerOf(tokenId)
        ) {
            revert NotListed(dooplicationAddress, tokenAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address tokenAddress,
        uint256 tokenId,
        address spender
    ) {
        address owner = IERC721(tokenAddress).ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isNotOwner(
        address tokenAddress,
        uint256 tokenId,
        address spender
    ) {
        address owner = IERC721(tokenAddress).ownerOf(tokenId);
        if (spender == owner) {
            revert IsOwner();
        }
        _;
    }

    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    /**
     * @notice Method for listing token
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     * @param price sale price for each item
     */
    function listItem(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(dooplicationAddress, tokenAddress, tokenId)
        isOwner(tokenAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (!_activeDooplications[dooplicationAddress]) {
            revert DooplicationContractNotActive(dooplicationAddress);
        }
        if (
            !IDooplication(dooplicationAddress).contractApproved(tokenAddress)
        ) {
            revert TokenContractNotApproved(dooplicationAddress, tokenAddress);
        }
        if (
            !IDooplication(dooplicationAddress).dooplicationActive(tokenAddress)
        ) {
            revert TokenContractNotActive(dooplicationAddress, tokenAddress);
        }
        if (
            IDooplication(dooplicationAddress).tokenDooplicated(
                tokenId,
                tokenAddress
            )
        ) {
            revert TokenHasBeenDooplicated(
                dooplicationAddress,
                tokenAddress,
                tokenId
            );
        }

        _listings[dooplicationAddress][tokenAddress][tokenId] = Listing(
            price,
            block.timestamp,
            msg.sender
        );
        EnumerableSet.add(
            _listingTokenIdSets[dooplicationAddress][tokenAddress],
            tokenId
        );
        emit ItemListed(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress,
            price
        );
    }

    /**
     * @notice Method for cancelling listing
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     */
    function cancelListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    )
        external
        isOwner(tokenAddress, tokenId, msg.sender)
        isListed(dooplicationAddress, tokenAddress, tokenId)
    {
        _deleteListing(dooplicationAddress, tokenAddress, tokenId);
        emit ItemCanceled(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress
        );
    }

    /**
     * @notice Method for dooplicating listing
     * The owner of a token could unapprove the marketplace or transfer the token to another address,
     * which would cause this function to fail.
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param dooplicatorId Dooplicator Id
     * @param tokenId Token Id
     * @param addressOnTheOtherSide An address you control, on the other side...
     * @param data Additional data to send in the transaction
     */
    function dooplicateItem(
        address dooplicationAddress,
        address tokenAddress,
        uint256 dooplicatorId,
        uint256 tokenId,
        bytes8 addressOnTheOtherSide,
        bytes calldata data
    )
        external
        payable
        isListed(dooplicationAddress, tokenAddress, tokenId)
        isNotOwner(tokenAddress, tokenId, msg.sender)
        nonReentrant
    {
        _validateDooplication(dooplicationAddress, tokenAddress, tokenId);
        _dooplicate(
            dooplicationAddress,
            tokenAddress,
            dooplicatorId,
            tokenId,
            addressOnTheOtherSide,
            data
        );
        _sendDooplicationPayments(dooplicationAddress, tokenAddress, tokenId);
        _deleteListing(dooplicationAddress, tokenAddress, tokenId);
    }

    /**
     * @notice Method for updating listing
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(dooplicationAddress, tokenAddress, tokenId)
        isOwner(tokenAddress, tokenId, msg.sender)
    {
        if (newPrice == 0) {
            revert PriceMustBeAboveZero();
        }
        _listings[dooplicationAddress][tokenAddress][tokenId].price = newPrice;
        emit ItemListed(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress,
            newPrice
        );
    }

    /**
     * @notice Set dooplication contract as active or inactive
     * @param dooplicationContract the contract to modify
     * @param active true to start dooplication, false to stop
     */
    function setActiveValidDooplication(
        address dooplicationContract,
        bool active
    ) external onlyRole(SUPPORT_ROLE) {
        _activeDooplications[dooplicationContract] = active;
    }

    /**
     * @notice Set token contract royalty.
     * This function set the receiver and the royalty fraction, and enable the royalties.
     * @param tokenAddress Address of token contract
     * @param receiver Address of receiver
     * @param royaltyFraction Royalty fraction in 1/10000
     */
    function setTokenRoyalty(
        address tokenAddress,
        address receiver,
        uint88 royaltyFraction
    ) external onlyRole(SUPPORT_ROLE) {
        if (receiver == address(0)) {
            revert InvalidRoyaltyReceiver();
        }
        if (royaltyFraction == 0 || royaltyFraction > 10000) {
            revert InvalidRoyaltyFraction();
        }
        _tokenRoyalties[tokenAddress] = TokenRoyalty(
            true,
            receiver,
            royaltyFraction
        );
    }

    /**
     * @notice Set token contract royalty as enabled or disabled.
     * To be enabled, the receiver and royalty fraction must be set.
     * @param tokenAddress Address of token contract
     * @param enabled True to enable, false to disable
     */
    function setTokenRoyaltyEnabled(
        address tokenAddress,
        bool enabled
    ) external onlyRole(SUPPORT_ROLE) {
        if (_tokenRoyalties[tokenAddress].receiver == address(0)) {
            revert InvalidRoyaltyReceiver();
        }
        if (
            _tokenRoyalties[tokenAddress].royaltyFraction == 0 ||
            _tokenRoyalties[tokenAddress].royaltyFraction > 10000
        ) {
            revert InvalidRoyaltyFraction();
        }
        _tokenRoyalties[tokenAddress].enabled = enabled;
    }

    /**
     * @notice Set token contract royalty receiver
     * @param tokenAddress Address of token contract
     * @param receiver Address of receiver
     */
    function setTokenRoyaltyReceiver(
        address tokenAddress,
        address receiver
    ) external onlyRole(SUPPORT_ROLE) {
        if (receiver == address(0)) {
            revert InvalidRoyaltyReceiver();
        }
        _tokenRoyalties[tokenAddress].receiver = receiver;
    }

    /**
     * @notice Set token contract royalty fraction
     * @param tokenAddress Address of token contract
     * @param royaltyFraction Royalty fraction in 1/10000
     */
    function setTokenRoyaltyFraction(
        address tokenAddress,
        uint88 royaltyFraction
    ) external onlyRole(SUPPORT_ROLE) {
        if (royaltyFraction == 0 || royaltyFraction > 10000) {
            revert InvalidRoyaltyFraction();
        }
        _tokenRoyalties[tokenAddress].royaltyFraction = royaltyFraction;
    }

    /**
     * @notice Check if a dooplication address is active to be used
     * @param dooplicationAddress Address of dooplication contract
     * @return True if active, false if not
     */
    function dooplicationContractActivated(
        address dooplicationAddress
    ) external view returns (bool) {
        return _activeDooplications[dooplicationAddress];
    }

    /**
     * @notice Get listing of a token on a dooplication contract.
     *   - If the token was already dooplicated, it is marked as not dooplicable.
     *   - If listing exists but the seller is not the owner of the token,
     *     it is marked as not dooplicable.
     *     This could happen if the seller transfer the token after the listing is created,
     *     but before the dooplication is done.
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @param tokenId Token Id
     * @return Listing data
     */
    function getListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (ListingView memory) {
        Listing memory listing = _listings[dooplicationAddress][tokenAddress][
            tokenId
        ];
        return
            ListingView(
                listing.price > 0 ? tokenId : 0,
                listing,
                listing.price > 0 &&
                    listing.seller == IERC721(tokenAddress).ownerOf(tokenId) &&
                    !IDooplication(dooplicationAddress).tokenDooplicated(
                        tokenId,
                        tokenAddress
                    )
            );
    }

    /**
     * @notice Get royalty data of a token contract
     * @param tokenAddress Address of token contract
     * @return Token Royalty data
     */
    function getTokenRoyalty(
        address tokenAddress
    ) external view returns (TokenRoyalty memory) {
        return _tokenRoyalties[tokenAddress];
    }

    /**
     * @notice Get the listings of a token contract on a dooplication contract.
     * Order is not guaranteed.
     * Take in consideration that not all the listings are dooplicable:
     *   - If the token was already dooplicated, it is marked as not dooplicable.
     *   - If the listing exists but the seller is not the owner of the token,
     *     it is marked as not dooplicable.
     *     This could happen if the seller transfer the token after the listing is created,
     *     but before the dooplication is done.
     * @param dooplicationAddress Address of dooplication contract
     * @param tokenAddress Address of token contract
     * @return Array of listings
     */
    function getListings(
        address dooplicationAddress,
        address tokenAddress
    ) external view returns (ListingView[] memory) {
        IERC721 token = IERC721(tokenAddress);
        IDooplication dooplication = IDooplication(dooplicationAddress);

        uint256 length = EnumerableSet.length(
            _listingTokenIdSets[dooplicationAddress][tokenAddress]
        );

        ListingView[] memory listings = new ListingView[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = EnumerableSet.at(
                _listingTokenIdSets[dooplicationAddress][tokenAddress],
                i
            );
            Listing memory listing = _listings[dooplicationAddress][
                tokenAddress
            ][tokenId];
            listings[i] = ListingView(
                tokenId,
                listing,
                listing.seller == token.ownerOf(tokenId) &&
                    !dooplication.tokenDooplicated(tokenId, tokenAddress)
            );
        }

        return listings;
    }

    function _validateDooplication(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        uint256 price = _listings[dooplicationAddress][tokenAddress][tokenId]
            .price;
        if (msg.value != price) {
            revert PriceNotMet(
                dooplicationAddress,
                tokenAddress,
                tokenId,
                price
            );
        }
    }

    function _dooplicate(
        address dooplicationAddress,
        address tokenAddress,
        uint256 dooplicatorId,
        uint256 tokenId,
        bytes8 addressOnTheOtherSide,
        bytes calldata data
    ) internal {
        Listing memory listedItem = _listings[dooplicationAddress][
            tokenAddress
        ][tokenId];
        emit ItemDooplicated(
            msg.sender,
            tokenAddress,
            tokenId,
            dooplicationAddress,
            listedItem.price
        );
        IDooplication(dooplicationAddress).dooplicate(
            dooplicatorId,
            msg.sender,
            tokenId,
            tokenAddress,
            listedItem.seller,
            addressOnTheOtherSide,
            data
        );
    }

    function _sendDooplicationPayments(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        address seller = _listings[dooplicationAddress][tokenAddress][tokenId]
            .seller;

        if (_tokenRoyalties[tokenAddress].enabled) {
            uint256 royaltyAmount = (msg.value *
                _tokenRoyalties[tokenAddress].royaltyFraction) / 10000;

            (bool success, ) = payable(seller).call{
                value: msg.value - royaltyAmount
            }("");
            require(success, "Seller transfer failed");

            (bool royaltySuccess, ) = payable(
                _tokenRoyalties[tokenAddress].receiver
            ).call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty transfer failed");
        } else {
            (bool success, ) = payable(seller).call{value: msg.value}("");
            require(success, "Transfer failed");
        }
    }

    function _deleteListing(
        address dooplicationAddress,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        delete _listings[dooplicationAddress][tokenAddress][tokenId];
        EnumerableSet.remove(
            _listingTokenIdSets[dooplicationAddress][tokenAddress],
            tokenId
        );
    }
}