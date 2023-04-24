// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "./IMarketplace.sol";
import "../library/CurrencyTransferLib.sol";

contract Marketplace is
    Initializable,
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    MulticallUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable,
    IMarketplace
{
    bytes32 private constant LIST_ROLE = keccak256("LIST_ROLE");
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    uint64 public constant MAX_BPS = 10000;

    address public nativeTokenWrapper;

    uint256 public totalListings;

    address private platformFeeWallet;
    uint64 private platformFeeBps;

    uint64 public timeBuffer;
    uint64 public bidBufferBps;

    mapping(uint256 => Listing) public listings;

    mapping(uint256 => mapping(address => Offer)) public offers;

    mapping(uint256 => Offer) winningBid;

    modifier onlyListingCreator(uint256 _listingId) {
        require(listings[_listingId].owner == _msgSender(), "Only owner");
        _;
    }

    modifier onlyExistingListing(uint256 _listingId) {
        require(
            listings[_listingId].assetAddress != address(0),
            "Invalid listing"
        );
        _;
    }

    function initialize(
        address _nativeTokenWrapper,
        address _platformFeeWallet,
        uint256 _platformFeeBps
    ) external initializer {
        __ReentrancyGuard_init();

        timeBuffer = 15 minutes;
        bidBufferBps = 500;

        nativeTokenWrapper = _nativeTokenWrapper;
        platformFeeWallet = _platformFeeWallet;
        platformFeeBps = uint64(_platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LIST_ROLE, address(0));
        _setupRole(ASSET_ROLE, address(0));
    }

    receive() external payable {}

    function createListing(ListingParams memory _params) external override {
        uint256 listingId = totalListings;
        totalListings += 1;

        address tokenOwner = _msgSender();
        TokenType tokenType = _getTokenType(_params.assetAddress);
        uint256 tokenAmount = _getSafeQuantity(tokenType, _params.quantity);

        require(tokenAmount > 0, "Invalid quantity");
        require(
            hasRole(LIST_ROLE, address(0)) || hasRole(LIST_ROLE, _msgSender()),
            "Only lister"
        );
        require(
            hasRole(ASSET_ROLE, address(0)) ||
                hasRole(ASSET_ROLE, _params.assetAddress),
            "Invalid asset"
        );

        uint256 startTime = _params.startTime;
        if (startTime < block.timestamp) {
            startTime = block.timestamp;
        }

        _validateOwnershipAndApproval(
            tokenOwner,
            _params.assetAddress,
            _params.tokenId,
            tokenAmount,
            tokenType
        );

        Listing memory newListing = Listing({
            listingId: listingId,
            owner: tokenOwner,
            assetAddress: _params.assetAddress,
            tokenId: _params.tokenId,
            startTime: startTime,
            endTime: startTime + _params.period,
            quantity: tokenAmount,
            currency: _params.currency,
            reservePricePerToken: _params.reservePricePerToken,
            buyoutPricePerToken: _params.buyoutPricePerToken,
            tokenType: tokenType,
            listingType: _params.listingType
        });

        listings[listingId] = newListing;

        if (newListing.listingType == ListingType.Auction) {
            require(
                newListing.buyoutPricePerToken == 0 ||
                    newListing.buyoutPricePerToken >=
                    newListing.reservePricePerToken,
                "Invalid buyout price"
            );
            _transferListingTokens(
                tokenOwner,
                address(this),
                tokenAmount,
                newListing
            );
        }

        emit ListingAdded(
            listingId,
            _params.assetAddress,
            tokenOwner,
            newListing
        );
    }

    function updateListing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        address _currency,
        uint256 _startTime,
        uint256 _period
    ) external override onlyListingCreator(_listingId) {
        Listing memory targetListing = listings[_listingId];

        uint256 safeQuantity = _getSafeQuantity(
            targetListing.tokenType,
            _quantity
        );
        bool isAuction = targetListing.listingType == ListingType.Auction;

        require(safeQuantity > 0, "Invalid quantity");

        if (isAuction) {
            require(
                block.timestamp < targetListing.startTime,
                "Already started"
            );
            require(
                _buyoutPricePerToken == 0 ||
                    _buyoutPricePerToken >= _reservePricePerToken,
                "Invalid buyout price"
            );
        }

        uint256 startTime = _startTime == 0
            ? targetListing.startTime
            : _startTime;

        if (startTime < block.timestamp) {
            startTime = block.timestamp;
        }

        Listing memory newListing = Listing({
            listingId: _listingId,
            owner: _msgSender(),
            assetAddress: targetListing.assetAddress,
            tokenId: targetListing.tokenId,
            startTime: startTime,
            endTime: _period == 0 ? targetListing.endTime : startTime + _period,
            quantity: safeQuantity,
            currency: _currency,
            reservePricePerToken: _reservePricePerToken,
            buyoutPricePerToken: _buyoutPricePerToken,
            tokenType: targetListing.tokenType,
            listingType: targetListing.listingType
        });

        listings[_listingId] = newListing;

        if (targetListing.quantity != safeQuantity) {
            if (isAuction) {
                _transferListingTokens(
                    address(this),
                    targetListing.owner,
                    targetListing.quantity,
                    targetListing
                );
            }

            _validateOwnershipAndApproval(
                targetListing.owner,
                targetListing.assetAddress,
                targetListing.tokenId,
                safeQuantity,
                targetListing.tokenType
            );

            if (isAuction) {
                _transferListingTokens(
                    targetListing.owner,
                    address(this),
                    safeQuantity,
                    targetListing
                );
            }
        }

        emit ListingUpdated(_listingId, targetListing.owner, newListing);
    }

    function cancelFixedListing(
        uint256 _listingId
    ) external override onlyListingCreator(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.listingType == ListingType.Fixed,
            "Only fixed offer"
        );

        delete listings[_listingId];

        emit ListingRemoved(_listingId, targetListing.owner);
    }

    function buy(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _price
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];
        address payer = _msgSender();

        require(
            _currency == targetListing.currency &&
                _price == targetListing.buyoutPricePerToken * _quantity,
            "Invalid price"
        );

        _executeSale(
            targetListing,
            payer,
            _buyFor,
            targetListing.currency,
            targetListing.buyoutPricePerToken * _quantity,
            _quantity
        );
    }

    function offer(
        uint256 _listingId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        uint256 _expTime
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.endTime > block.timestamp &&
                targetListing.startTime < block.timestamp,
            "inactive listing"
        );

        Offer memory newOffer = Offer({
            listingId: _listingId,
            offeror: _msgSender(),
            quantity: _quantity,
            currency: _currency,
            pricePerToken: _pricePerToken,
            expTime: _expTime
        });

        if (targetListing.listingType == ListingType.Auction) {
            require(
                newOffer.currency == targetListing.currency,
                "Not approved currency to bid"
            );
            require(newOffer.pricePerToken > 0, "Zero amount");

            newOffer.quantity = _getSafeQuantity(
                targetListing.tokenType,
                targetListing.quantity
            );

            _handleBid(targetListing, newOffer);
        } else if (targetListing.listingType == ListingType.Fixed) {
            require(msg.value == 0, "no value needed");

            newOffer.currency = _currency == CurrencyTransferLib.NATIVE_TOKEN
                ? nativeTokenWrapper
                : _currency;

            newOffer.quantity = _getSafeQuantity(
                targetListing.tokenType,
                _quantity
            );

            _handleOffer(targetListing, newOffer);
        }
    }

    function acceptOffer(
        uint256 _listingId,
        address _offeror,
        address _currency,
        uint256 _price
    )
        external
        override
        nonReentrant
        onlyListingCreator(_listingId)
        onlyExistingListing(_listingId)
    {
        Offer memory targetOffer = offers[_listingId][_offeror];
        Listing memory targetListing = listings[_listingId];

        require(
            _currency == targetOffer.currency &&
                _price == targetOffer.pricePerToken,
            "Invalid price"
        );
        require(targetOffer.expTime > block.timestamp, "Offer expired");

        delete offers[_listingId][_offeror];

        _executeSale(
            targetListing,
            _offeror,
            _offeror,
            targetOffer.currency,
            targetOffer.pricePerToken * targetOffer.quantity,
            targetOffer.quantity
        );
    }

    function closeAuction(
        uint256 _listingId,
        address _closeFor
    ) external override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.listingType == ListingType.Auction,
            "not an auction"
        );

        Offer memory targetBid = winningBid[_listingId];

        bool toCancel = targetListing.startTime > block.timestamp ||
            targetBid.offeror == address(0);

        if (toCancel) {
            _cancelAuction(targetListing);
        } else {
            require(
                targetListing.endTime < block.timestamp,
                "cannot close auction before it has ended"
            );

            if (_closeFor == targetListing.owner) {
                _closeAuctionForAuctionCreator(targetListing, targetBid);
            }

            if (_closeFor == targetBid.offeror) {
                _closeAuctionForBidder(targetListing, targetBid);
            }
        }
    }

    function getPlatformFeeInfo()
        external
        view
        override
        returns (address, uint16)
    {
        return (platformFeeWallet, uint16(platformFeeBps));
    }

    function setPlatformFeeInfo(
        address _platformFeeWallet,
        uint256 _platformFeeBps
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_platformFeeBps <= MAX_BPS, "exceeds max bps");

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeWallet = _platformFeeWallet;

        emit PlatformFeeInfoUpdated(_platformFeeWallet, _platformFeeBps);
    }

    function setAuctionBuffers(
        uint256 _timeBuffer,
        uint256 _bidBufferBps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bidBufferBps < MAX_BPS, "Invalid BPS");

        timeBuffer = uint64(_timeBuffer);
        bidBufferBps = uint64(_bidBufferBps);

        emit AuctionBufferUpdated(_timeBuffer, _bidBufferBps);
    }

    function getAllListings(
        uint256 _startId,
        uint256 _endId
    ) external view override returns (Listing[] memory _allListings) {
        require(_startId < _endId && _endId <= totalListings, "Invalid range");

        _allListings = new Listing[](_endId - _startId + 1);

        for (uint256 i = _startId; i < _endId; i++) {
            _allListings[i - _startId] = listings[i];
        }
    }

    function getAllValidListings(
        uint256 _startId,
        uint256 _endId
    ) external view override returns (Listing[] memory _validListings) {
        require(_startId < _endId && _endId <= totalListings, "Invalid range");

        uint256 _listingCount = 0;
        for (uint256 i = _startId; i < _endId; i++) {
            if (_validateActiveListing(listings[i])) {
                _listingCount += 1;
            }
        }

        _validListings = new Listing[](_listingCount);
        uint256 _listingIndex = 0;
        for (uint256 i = _startId; i < _endId; i++) {
            if (_validateActiveListing(listings[i])) {
                _validListings[_listingIndex] = listings[i];
                _listingIndex += 1;
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        Listing memory _listing
    ) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(_listing.assetAddress).safeTransferFrom(
                _from,
                _to,
                _listing.tokenId,
                _quantity,
                ""
            );
        } else if (_listing.tokenType == TokenType.ERC721) {
            IERC721Upgradeable(_listing.assetAddress).safeTransferFrom(
                _from,
                _to,
                _listing.tokenId,
                ""
            );
        }
    }

    function _executeSale(
        Listing memory _targetListing,
        address _payer,
        address _receiver,
        address _currency,
        uint256 _price,
        uint256 _quantity
    ) internal {
        _validateFixedListingSale(
            _targetListing,
            _payer,
            _quantity,
            _currency,
            _price
        );

        _targetListing.quantity -= _quantity;
        listings[_targetListing.listingId] = _targetListing;

        _payout(
            _payer,
            _targetListing.owner,
            _currency,
            _price,
            _targetListing
        );

        _transferListingTokens(
            _targetListing.owner,
            _receiver,
            _quantity,
            _targetListing
        );

        emit NewSale(
            _targetListing.listingId,
            _targetListing.assetAddress,
            _targetListing.owner,
            _receiver,
            _quantity,
            _price
        );
    }

    function _payout(
        address _payer,
        address _payee,
        address _currency,
        uint256 _amount,
        Listing memory _listing
    ) internal {
        uint256 platformFeeCut = (_amount * platformFeeBps) / MAX_BPS;

        uint256 royaltyCut;
        address royaltyRecipient;

        try
            IERC2981Upgradeable(_listing.assetAddress).royaltyInfo(
                _listing.tokenId,
                _amount
            )
        returns (address royaltyFeeRecipient, uint256 royaltyFeeAmount) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                require(
                    royaltyFeeAmount + platformFeeCut <= _amount,
                    "fees exceed the price"
                );
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        address _nativeTokenWrapper = nativeTokenWrapper;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currency,
            _payer,
            platformFeeWallet,
            platformFeeCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currency,
            _payer,
            royaltyRecipient,
            royaltyCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currency,
            _payer,
            _payee,
            _amount - (platformFeeCut + royaltyCut),
            _nativeTokenWrapper
        );
    }

    function _handleBid(
        Listing memory _targetListing,
        Offer memory _incomingBid
    ) internal {
        Offer memory currentWinningBid = winningBid[_targetListing.listingId];

        uint256 currentOfferAmount = currentWinningBid.pricePerToken *
            currentWinningBid.quantity;
        uint256 incomingOfferAmount = _incomingBid.pricePerToken *
            _incomingBid.quantity;

        address _nativeTokenWrapper = nativeTokenWrapper;

        if (
            _targetListing.buyoutPricePerToken > 0 &&
            incomingOfferAmount >=
            _targetListing.buyoutPricePerToken * _targetListing.quantity
        ) {
            _closeAuctionForBidder(_targetListing, _incomingBid);
        } else {
            require(
                _isNewWinningBid(
                    _targetListing.reservePricePerToken *
                        _targetListing.quantity,
                    currentOfferAmount,
                    incomingOfferAmount
                ),
                "not winning bid"
            );

            winningBid[_targetListing.listingId] = _incomingBid;

            if (_targetListing.endTime - block.timestamp <= timeBuffer) {
                _targetListing.endTime += timeBuffer;
                listings[_targetListing.listingId] = _targetListing;
            }
        }

        if (currentWinningBid.offeror != address(0) && currentOfferAmount > 0) {
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _targetListing.currency,
                address(this),
                currentWinningBid.offeror,
                currentOfferAmount,
                _nativeTokenWrapper
            );
        }

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _targetListing.currency,
            _incomingBid.offeror,
            address(this),
            incomingOfferAmount,
            _nativeTokenWrapper
        );

        emit NewOffer(
            _targetListing.listingId,
            _incomingBid.offeror,
            _targetListing.listingType,
            _incomingBid.quantity,
            _incomingBid.pricePerToken * _incomingBid.quantity,
            _incomingBid.currency
        );
    }

    function _handleOffer(
        Listing memory _targetListing,
        Offer memory _newOffer
    ) internal {
        require(
            _newOffer.quantity <= _targetListing.quantity &&
                _targetListing.quantity > 0,
            "insufficient tokens in listing"
        );

        _validateERC20BalanceAndAllowance(
            _newOffer.offeror,
            _newOffer.currency,
            _newOffer.pricePerToken * _newOffer.quantity
        );

        offers[_targetListing.listingId][_newOffer.offeror] = _newOffer;

        emit NewOffer(
            _targetListing.listingId,
            _newOffer.offeror,
            _targetListing.listingType,
            _newOffer.quantity,
            _newOffer.pricePerToken * _newOffer.quantity,
            _newOffer.currency
        );
    }

    function _closeAuctionForBidder(
        Listing memory _targetListing,
        Offer memory _winningBid
    ) internal {
        uint256 quantity = _winningBid.quantity;

        _targetListing.endTime = block.timestamp;
        _winningBid.quantity = 0;

        winningBid[_targetListing.listingId] = _winningBid;
        listings[_targetListing.listingId] = _targetListing;

        _transferListingTokens(
            address(this),
            _winningBid.offeror,
            quantity,
            _targetListing
        );

        emit AuctionClosed(
            _targetListing.listingId,
            _msgSender(),
            false,
            _targetListing.owner,
            _winningBid.offeror
        );
    }

    function _closeAuctionForAuctionCreator(
        Listing memory _targetListing,
        Offer memory _winningBid
    ) internal {
        uint256 payoutAmount = _winningBid.pricePerToken *
            _targetListing.quantity;

        _targetListing.quantity = 0;
        _targetListing.endTime = block.timestamp;
        listings[_targetListing.listingId] = _targetListing;

        _winningBid.pricePerToken = 0;
        winningBid[_targetListing.listingId] = _winningBid;

        _payout(
            address(this),
            _targetListing.owner,
            _targetListing.currency,
            payoutAmount,
            _targetListing
        );

        emit AuctionClosed(
            _targetListing.listingId,
            _msgSender(),
            false,
            _targetListing.owner,
            _winningBid.offeror
        );
    }

    function _cancelAuction(Listing memory _targetListing) internal {
        require(
            listings[_targetListing.listingId].owner == _msgSender(),
            "only creator can cancel"
        );

        delete listings[_targetListing.listingId];

        _transferListingTokens(
            address(this),
            _targetListing.owner,
            _targetListing.quantity,
            _targetListing
        );

        emit AuctionClosed(
            _targetListing.listingId,
            _msgSender(),
            true,
            _targetListing.owner,
            address(0)
        );
    }

    function _getTokenType(
        address _assetAddress
    ) internal view returns (TokenType tokenType) {
        if (
            IERC165Upgradeable(_assetAddress).supportsInterface(
                type(IERC1155Upgradeable).interfaceId
            )
        ) {
            tokenType = TokenType.ERC1155;
        } else if (
            IERC165Upgradeable(_assetAddress).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Unsupported token type");
        }
    }

    function _getSafeQuantity(
        TokenType _tokenType,
        uint256 _quantity
    ) internal pure returns (uint256 safeQuantity) {
        if (_quantity == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721 ? 1 : _quantity;
        }
    }

    function _validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetAddress,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view {
        address self = address(this);
        bool isValid;

        if (_tokenType == TokenType.ERC1155) {
            isValid =
                IERC1155Upgradeable(_assetAddress).balanceOf(
                    _tokenOwner,
                    _tokenId
                ) >=
                _quantity &&
                IERC1155Upgradeable(_assetAddress).isApprovedForAll(
                    _tokenOwner,
                    self
                );
        } else if (_tokenType == TokenType.ERC721) {
            isValid =
                IERC721Upgradeable(_assetAddress).ownerOf(_tokenId) ==
                _tokenOwner &&
                (IERC721Upgradeable(_assetAddress).getApproved(_tokenId) ==
                    self ||
                    IERC721Upgradeable(_assetAddress).isApprovedForAll(
                        _tokenOwner,
                        self
                    ));
        }

        require(isValid, "Invalid token");
    }

    function _validateFixedListingSale(
        Listing memory _listing,
        address _payer,
        uint256 _quantity,
        address _currency,
        uint256 _price
    ) internal {
        require(_listing.listingType == ListingType.Fixed, "Only fixed offer");

        require(
            _listing.quantity > 0 &&
                _quantity > 0 &&
                _quantity <= _listing.quantity,
            "Invalid amount of tokens"
        );

        require(
            block.timestamp < _listing.endTime &&
                block.timestamp > _listing.startTime,
            "not within sale window"
        );

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == _price, "Invalid native token");
        } else {
            _validateERC20BalanceAndAllowance(_payer, _currency, _price);
        }

        _validateOwnershipAndApproval(
            _listing.owner,
            _listing.assetAddress,
            _listing.tokenId,
            _quantity,
            _listing.tokenType
        );
    }

    function _validateERC20BalanceAndAllowance(
        address _address,
        address _currency,
        uint256 _amount
    ) internal view {
        require(
            IERC20Upgradeable(_currency).balanceOf(_address) >= _amount &&
                IERC20Upgradeable(_currency).allowance(
                    _address,
                    address(this)
                ) >=
                _amount,
            "Invalid balance and allowance"
        );
    }

    function _isNewWinningBid(
        uint256 _reserveAmount,
        uint256 _currentWinningBidAmount,
        uint256 _incomingBidAmount
    ) internal view returns (bool isValidNewBid) {
        if (_currentWinningBidAmount == 0) {
            isValidNewBid = _incomingBidAmount >= _reserveAmount;
        } else {
            isValidNewBid = (_incomingBidAmount > _currentWinningBidAmount &&
                ((_incomingBidAmount - _currentWinningBidAmount) * MAX_BPS) /
                    _currentWinningBidAmount >=
                bidBufferBps);
        }
    }

    function _validateActiveListing(
        Listing memory _listing
    ) internal view returns (bool isValid) {
        isValid =
            _listing.startTime <= block.timestamp &&
            _listing.endTime >= block.timestamp;
    }
}