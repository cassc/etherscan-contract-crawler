// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

//  ==========  Internal imports    ==========

import {IMarketplace} from "./BaseContracts/IMarketplace.sol";

import "./BaseContracts/ERC2771ContextUpgradeable.sol";

import "./Utils/CurrencyTransferLib.sol";
import "./Utils/FeeType.sol";


error RoyaltyExceedsPayout();
error ExceedsMaxBPS();
error ExpiredSale();
error UnapprovedCurrency();
error AuctionNotConcluded();
error AmountExceedsTopOffer();
error TokenAmountZero();


contract DaoMarketPlace is
    Initializable,
    IMarketplace,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    AccessControlUpgradeable, 
    UUPSUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    


    address private nativeTokenWrapper = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private tokenWrapper;

    /// @dev Total number of listings ever created in the marketplace.
    uint256 public totalListings;

    
    /// @dev The address that receives all platform fees from all sales.
    address public platformFeeRecipient;

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The % of primary sales collected as platform fees.
    uint64 public platformFeeBps;

    /// @dev
    /**
     *  @dev The amount of time added to an auction's 'endTime', if a bid is made within `timeBuffer`
     *       seconds of the existing `endTime`. Default: 15 minutes.
     */
    uint64 public timeBuffer;

    /// @dev The minimum % increase required from the previous winning bid. Default: 5%.
    uint64 public bidBufferBps;

    /// @dev listing fee
    //uint256 public listingFee;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Allowed contracts to list
    mapping(address => bool) public allowedContracts;

    /// @dev Mapping from uid of listing => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev Mapping from uid of a direct listing => offeror address => offer made to the direct listing by the respective offeror.
    mapping(address => mapping(uint256 => ExsistListing)) public exsist;

    /// @dev Mapping from uid of a direct listing => offeror address => offer made to the direct listing by the respective offeror.
    mapping(uint256 => mapping(address => Offer)) public offers;

    /// @dev Mapping from uid of an auction listing => current winning bid in an auction.
    mapping(uint256 => Offer) public winningBid;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether caller is a listing creator.
    modifier onlyListingCreator(uint256 _listingId) {
        require(listings[_listingId].tokenOwner == _msgSender(), "!OWNER");
        _;
    }

    /// @dev Checks whether a listing exists.
    modifier onlyExistingListing(uint256 _listingId) {
        require(listings[_listingId].assetContract != address(0), "DNE");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/
    

function initialize(address owner, address _nativeTokenWrapper) initializer public {
    address[] memory ctrustedForwarders = new address[](1);
        uint64 cplatformFeeBps = 100;
        __AccessControl_init();
        __UUPSUpgradeable_init();

         __ReentrancyGuard_init();
        __ERC2771Context_init(ctrustedForwarders);

         timeBuffer = 15 minutes;
        bidBufferBps = 500;

        nativeTokenWrapper = _nativeTokenWrapper;
        tokenWrapper = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        platformFeeBps = uint64(cplatformFeeBps);
        platformFeeRecipient = owner;

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(LISTER_ROLE, address(0));
        _setupRole(ASSET_ROLE, address(0));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
    

    

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets the contract receives native tokens from `nativeTokenWrapper` withdraw.
    receive() external payable {}

   

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 1155 logic
    //////////////////////////////////////////////////////////////*/

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
        override(AccessControlUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                Listing (create-update-delete) logic
    //////////////////////////////////////////////////////////////*/
/*
    function captureListingFee(address _currencyToUse) internal {
        require(msg.value >= listingFee, "!FEE");

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _msgSender(),
            platformFeeRecipient,
            listingFee,
            nativeTokenWrapper
        );
    }*/

    

    /// @dev Lets a token owner list tokens for sale: Direct Listing or Auction.
    function createListing(ListingParameters memory _params) internal {
        // Get values to populate `Listing`.
        uint256 listingId = totalListings;
        
        address tokenOwner = _msgSender();
        TokenType tokenTypeOfListing = getTokenType(_params.assetContract);
        uint256 tokenAmountToList = getSafeQuantity(
            tokenTypeOfListing,
            _params.quantityToList
        );

        require(allowedContracts[_params.assetContract], "EO1");

        if(tokenAmountToList == 0){
            revert TokenAmountZero();
        }
        require(
            hasRole(LISTER_ROLE, address(0)) ||
                hasRole(LISTER_ROLE, _msgSender()),
            "EO3"
        );
        require(
            hasRole(ASSET_ROLE, address(0)) ||
                hasRole(ASSET_ROLE, _params.assetContract),
            "EO1"
        );

        uint256 startTime = _params.startTime;
        if (startTime < block.timestamp) {
            // do not allow listing to start in the past (1 hour buffer)
            require(block.timestamp - startTime < 1 hours, "ST");
            startTime = block.timestamp;
        }

        checkAlreadyListing(
            _params.assetContract,
            _params.tokenId
        );
        /*
        captureListingFee(
            _params.currencyToAccept
        );*/

        validateOwnershipAndApproval(
            tokenOwner,
            _params.assetContract,
            _params.tokenId,
            tokenAmountToList,
            tokenTypeOfListing
        );

        Listing memory newListing = Listing({
            listingId: listingId,
            tokenHash: _params.tokenHash,
            tokenOwner: tokenOwner,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            startTime: startTime,
            endTime: startTime + _params.secondsUntilEndTime,
            quantity: tokenAmountToList,
            currency: _params.currencyToAccept,
            reservePricePerToken: _params.reservePricePerToken,
            buyoutPricePerToken: _params.buyoutPricePerToken,
            tokenType: tokenTypeOfListing,
            listingType: _params.listingType
        });

        listings[listingId] = newListing;
        exsist[_params.assetContract][_params.tokenId] = ExsistListing({
            listingId: listingId,
            buyoutPricePerToken: _params.buyoutPricePerToken,
            reservePricePerToken: _params.reservePricePerToken,
            isExist: true,
            listingType: _params.listingType,
            startTime: startTime,
            endTime: startTime + _params.secondsUntilEndTime
        });

        // Tokens listed for sale in an auction are escrowed in Marketplace.
        if (newListing.listingType == ListingType.Auction) {
            require(
                newListing.buyoutPricePerToken >=
                    newListing.reservePricePerToken,
                "EO4"
            );
            transferListingTokens(
                tokenOwner,
                address(this),
                tokenAmountToList,
                newListing
            );
        }

        totalListings += 1;


        emit ListingAdded(
            listingId,
            _params.tokenHash,
            _params.assetContract,
            tokenOwner,
            newListing
        );
    }


    function bulkCreateSell (
        address assetContract,
        uint256[] calldata tokenId,
        address[] calldata tokenHash,
        uint256[] calldata price,
        uint256[] calldata endSeconds
    ) external {
        for(uint8 i; i< tokenId.length; i++){
            
            createSell(
                
                    assetContract,
                    tokenId[i],
                    tokenHash[i],
                    price[i], 
                    endSeconds[i]
                );
            
        }
    }
    

    function createSell(
        address assetContract,
        uint256 tokenId,
        address tokenHash,
        uint256 price,
        uint256 endSeconds
    ) public {
        createListing(
            ListingParameters({
                assetContract: assetContract,
                tokenId: tokenId,
                tokenHash: tokenHash,
                startTime: block.timestamp,
                secondsUntilEndTime: endSeconds,
                quantityToList: 1,
                currencyToAccept: tokenWrapper,
                reservePricePerToken: 0,
                buyoutPricePerToken: price,
                listingType: ListingType.Direct
            })
        );
    }

    function bulkCreateAuction(
        address assetContract,
        uint256[] calldata tokenId,
        address[] calldata tokenHash,
        uint256[] calldata bidStartPrice,
        uint256[] calldata buyPrice,
        uint256[] calldata endSeconds
    ) external {
        for(uint8 i; i< tokenId.length; i++){
            
            createAuction(
                
                    assetContract,
                    tokenId[i],
                    tokenHash[i],
                    bidStartPrice[i], 
                    buyPrice[i],
                    endSeconds[i]
                );
            
        }
    }
    

    function createAuction(
        address assetContract,
        uint256 tokenId,
        address tokenHash,
        uint256 bidStartPrice,
        uint256 buyPrice,
        uint256 endSeconds
    ) public {
        createListing(
            ListingParameters({
                assetContract: assetContract,
                tokenId: tokenId,
                tokenHash: tokenHash,
                startTime: block.timestamp,
                secondsUntilEndTime: endSeconds,
                quantityToList: 1,
                currencyToAccept: tokenWrapper,
                reservePricePerToken: bidStartPrice,
                buyoutPricePerToken: buyPrice,
                listingType: ListingType.Auction
            })
        );
    }

    function updateListing(
        uint256 _listingId,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        uint256 endSeconds
    ) external override onlyListingCreator(_listingId) {
        _updateListing(
            _listingId,
            1,
            _reservePricePerToken,
            _buyoutPricePerToken,
            tokenWrapper,
            block.timestamp,
            endSeconds
        );
    }

    /// @dev Lets a listing's creator edit the listing's parameters.
    function _updateListing(
        uint256 _listingId,
        uint256 _quantityToList,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        address _currencyToAccept,
        uint256 _startTime,
        uint256 _secondsUntilEndTime
    ) internal onlyListingCreator(_listingId) {
        Listing memory targetListing = listings[_listingId];
        uint256 safeNewQuantity = getSafeQuantity(
            targetListing.tokenType,
            _quantityToList
        );
        bool isAuction = targetListing.listingType == ListingType.Auction;

        require(safeNewQuantity != 0, "EO2");

        // Can only edit auction listing before it starts.
        if (isAuction) {
            require(block.timestamp < targetListing.startTime, "EO5");
            require(_buyoutPricePerToken >= _reservePricePerToken, "EO4");
        }

        if (_startTime < block.timestamp) {
            // do not allow listing to start in the past (1 hour buffer)
            require(block.timestamp - _startTime < 1 hours, "ST");
            _startTime = block.timestamp;
        }

        uint256 newStartTime = _startTime == 0
            ? targetListing.startTime
            : _startTime;
        listings[_listingId] = Listing({
            listingId: _listingId,
            tokenHash: targetListing.tokenHash,
            tokenOwner: _msgSender(),
            assetContract: targetListing.assetContract,
            tokenId: targetListing.tokenId,
            startTime: newStartTime,
            endTime: _secondsUntilEndTime == 0
                ? targetListing.endTime
                : newStartTime + _secondsUntilEndTime,
            quantity: safeNewQuantity,
            currency: _currencyToAccept,
            reservePricePerToken: _reservePricePerToken,
            buyoutPricePerToken: _buyoutPricePerToken,
            tokenType: targetListing.tokenType,
            listingType: targetListing.listingType
        });

        exsist[targetListing.assetContract][targetListing.tokenId] = ExsistListing({
            listingId: _listingId,
            buyoutPricePerToken: _buyoutPricePerToken,
            reservePricePerToken: _reservePricePerToken,
            isExist:true,
            listingType: targetListing.listingType,
            startTime: newStartTime,
            endTime: _secondsUntilEndTime == 0
                ? targetListing.endTime
                : newStartTime + _secondsUntilEndTime
        });

        // Must validate ownership and approval of the new quantity of tokens for diret listing.
        if (targetListing.quantity != safeNewQuantity) {
            // Transfer all escrowed tokens back to the lister, to be reflected in the lister's
            // balance for the upcoming ownership and approval check.
            if (isAuction) {
                transferListingTokens(
                    address(this),
                    targetListing.tokenOwner,
                    targetListing.quantity,
                    targetListing
                );
            }

            validateOwnershipAndApproval(
                targetListing.tokenOwner,
                targetListing.assetContract,
                targetListing.tokenId,
                safeNewQuantity,
                targetListing.tokenType
            );

            // Escrow the new quantity of tokens to list in the auction.
            if (isAuction) {
                transferListingTokens(
                    targetListing.tokenOwner,
                    address(this),
                    safeNewQuantity,
                    targetListing
                );
            }
        }

        emit ListingUpdated(_listingId, targetListing.tokenHash, targetListing.tokenOwner);
    }

    /// @dev Lets a direct listing creator cancel their listing.
    function cancelDirectListing(
        uint256 _listingId
    ) external onlyListingCreator(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(targetListing.listingType == ListingType.Direct, "!DIRECT");

        delete listings[_listingId];
        delete exsist[targetListing.assetContract][targetListing.tokenId];

        /*
        transferListingTokens(
            address(this),
            targetListing.tokenOwner,
            targetListing.quantity,
            targetListing
        );*/

        emit ListingRemoved(_listingId, targetListing.tokenHash , targetListing.tokenOwner);
    }

    /*///////////////////////////////////////////////////////////////
                    Direct lisitngs sales logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(
        uint256 _listingId
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        address _buyFor = msg.sender;
        uint256 _quantityToBuy = 1;
        address _currency = tokenWrapper;
        uint256 _totalPrice = msg.value;
        Listing memory targetListing = listings[_listingId];
        address payer = _msgSender();

        // Check whether the settled total price and currency to use are correct.
        require(
            _currency == targetListing.currency &&
                _totalPrice >=
                (targetListing.buyoutPricePerToken * _quantityToBuy),
            "EO6"
        );

        executeSale(
            targetListing,
            payer,
            _buyFor,
            targetListing.currency,
            targetListing.buyoutPricePerToken * _quantityToBuy,
            _quantityToBuy
        );
    }

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    /*
    function acceptOffer(
        uint256 _listingId,
        uint256 _pricePerToken
    )
        external
        override
        nonReentrant
        onlyListingCreator(_listingId)
        onlyExistingListing(_listingId)
    {
        address _offeror = msg.sender;
        address _currency = tokenWrapper;
        Offer memory targetOffer = offers[_listingId][_offeror];
        Listing memory targetListing = listings[_listingId];

        if(
            _currency != targetOffer.currency ||
                _pricePerToken > targetOffer.pricePerToken){
                    revert AmountExceedsTopOffer();
                }
            
        require(targetOffer.expirationTimestamp > block.timestamp, "EXPIRED");

        delete offers[_listingId][_offeror];

        executeSale(
            targetListing,
            _offeror,
            _offeror,
            targetOffer.currency,
            targetOffer.pricePerToken * targetOffer.quantityWanted,
            targetOffer.quantityWanted
        );
    }*/

    /// @dev Performs a direct listing sale.
    function executeSale(
        Listing memory _targetListing,
        address _payer,
        address _receiver,
        address _currency,
        uint256 _currencyAmountToTransfer,
        uint256 _listingTokenAmountToTransfer
    ) internal {
        validateDirectListingSale(
            _targetListing,
            _payer,
            _listingTokenAmountToTransfer,
            _currency,
            _currencyAmountToTransfer
        );
        

        _targetListing.quantity -= _listingTokenAmountToTransfer;
        listings[_targetListing.listingId] = _targetListing;

        payout(
            _payer,
            _targetListing.tokenOwner,
            _currency,
            _currencyAmountToTransfer,
            _targetListing
        );
        
        transferListingTokens(
            _targetListing.tokenOwner,
            _receiver,
            _listingTokenAmountToTransfer,
            _targetListing
        );
        
        delete exsist[_targetListing.assetContract][_targetListing.tokenId];

        emit NewSale(
            _targetListing.listingId,
            _targetListing.tokenHash,
            _targetListing.assetContract,
            _targetListing.tokenOwner,
            _receiver,
            _listingTokenAmountToTransfer,
            _currencyAmountToTransfer
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Offer/bid logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account (1) make an offer to a direct listing, or (2) make a bid in an auction.

    
    function offer(
        uint256 _listingId
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];
        //uint256 _quantityWanted = 1;
        address _currency = tokenWrapper;
        //uint256 _expirationTimestamp = 1440 minutes;
        uint256 _pricePerToken = msg.value;
        

        require(
            targetListing.endTime > block.timestamp &&
                targetListing.startTime < block.timestamp,
            "EO8"
        );

        

        // Both - (1) offers to direct listings, and (2) bids to auctions - share the same structure.
        Offer memory newOffer = Offer({
            listingId: _listingId,
            offeror: _msgSender(),
            quantityWanted: 1,
            currency: _currency,
            pricePerToken: _pricePerToken,
            expirationTimestamp: 1440 minutes
        });

        if (targetListing.listingType == ListingType.Auction) {
            // A bid to an auction must be made in the auction's desired currency.
            if(
                newOffer.currency != targetListing.currency){
                    revert UnapprovedCurrency();
                }

            // A bid must be made for all auction items.
            /*
            newOffer.quantityWanted = getSafeQuantity(
                targetListing.tokenType,
                targetListing.quantity
            );*/

            handleBid(targetListing, newOffer);
        } else if (targetListing.listingType == ListingType.Direct) {
            // Prevent potentially lost/locked native token.
            
            
            revert("EO10");

            // Offers to direct listings cannot be made directly in native tokens.
            /*
            newOffer.currency = _currency == CurrencyTransferLib.NATIVE_TOKEN
                ? nativeTokenWrapper
                : _currency;
              
            newOffer.quantityWanted = getSafeQuantity(
                targetListing.tokenType,
                _quantityWanted
            );

            handleOffer(targetListing, newOffer);*/
        }
    }

    /// @dev Processes a new offer to a direct listing.
    /*
    function handleOffer(
        Listing memory _targetListing,
        Offer memory _newOffer
    ) internal {
        

        validateERC20BalAndAllowance(
            _newOffer.offeror,
            _newOffer.currency,
            _newOffer.pricePerToken
        );

        offers[_targetListing.listingId][_newOffer.offeror] = _newOffer;

        emit NewOffer(
            _targetListing.listingId,
            _targetListing.tokenHash,
            _newOffer.offeror,
            _targetListing.listingType,
            _newOffer.quantityWanted,
            _newOffer.pricePerToken,
            _newOffer.currency
        );
    }*/

    /// @dev Processes an incoming bid in an auction.
    function handleBid(
        Listing memory _targetListing,
        Offer memory _incomingBid
    ) internal {
        Offer memory currentWinningBid = winningBid[_targetListing.listingId];
        uint256 currentOfferAmount = currentWinningBid.pricePerToken *
            currentWinningBid.quantityWanted;
        uint256 incomingOfferAmount = _incomingBid.pricePerToken *
            _incomingBid.quantityWanted;
        address _nativeTokenWrapper = nativeTokenWrapper;

        // Close auction and execute sale if there's a buyout price and incoming offer amount is buyout price.
        if (
            _targetListing.buyoutPricePerToken > 0 &&
            incomingOfferAmount >=
            _targetListing.buyoutPricePerToken * _targetListing.quantity
        ) {
            _closeAuctionForBidder(_targetListing, _incomingBid);
        } else {
            /**
             *      If there's an exisitng winning bid, incoming bid amount must be bid buffer % greater.
             *      Else, bid amount must be at least as great as reserve price
             */
            require(
                isNewWinningBid(
                    _targetListing.reservePricePerToken *
                        _targetListing.quantity,
                    currentOfferAmount,
                    incomingOfferAmount
                ),
                "EO12"
            );

            // Update the winning bid and listing's end time before external contract calls.
            winningBid[_targetListing.listingId] = _incomingBid;

            if (_targetListing.endTime - block.timestamp <= timeBuffer) {
                _targetListing.endTime += timeBuffer;
                listings[_targetListing.listingId] = _targetListing;
            }
        }

        // Payout previous highest bid.
        if (currentWinningBid.offeror != address(0) && currentOfferAmount > 0) {
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _targetListing.currency,
                address(this),
                currentWinningBid.offeror,
                currentOfferAmount,
                _nativeTokenWrapper
            );
        }

        // Collect incoming bid
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _targetListing.currency,
            _incomingBid.offeror,
            address(this),
            incomingOfferAmount,
            _nativeTokenWrapper
        );

        emit NewOffer(
            _targetListing.listingId,
            _targetListing.tokenHash,
            _incomingBid.offeror,
            _targetListing.listingType,
            _incomingBid.quantityWanted,
            _incomingBid.pricePerToken * _incomingBid.quantityWanted,
            _incomingBid.currency
        );
    }

    /// @dev Checks whether an incoming bid is the new current highest bid.
    function isNewWinningBid(
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

    /*///////////////////////////////////////////////////////////////
                    Auction lisitngs sales logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account close an auction for either the (1) winning bidder, or (2) auction creator.
    function closeAuction(
        uint256 _listingId,
        address _closeFor
    ) external override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.listingType == ListingType.Auction,
            "EO13"
        );

        Offer memory targetBid = winningBid[_listingId];

        // Cancel auction if (1) auction hasn't started, or (2) auction doesn't have any bids.
        bool toCancel = targetListing.startTime > block.timestamp ||
            targetBid.offeror == address(0);

        if (toCancel) {
            // cancel auction listing owner check
            _cancelAuction(targetListing);
        } else {
            if(
                targetListing.endTime > block.timestamp){
                    revert AuctionNotConcluded();
                }

            // No `else if` to let auction close in 1 tx when targetListing.tokenOwner == targetBid.offeror.
            if (_closeFor == targetListing.tokenOwner) {
                _closeAuctionForAuctionCreator(targetListing, targetBid);
            }

            if (_closeFor == targetBid.offeror) {
                _closeAuctionForBidder(targetListing, targetBid);
            }
        }
    }

    /// @dev Cancels an auction.
    function _cancelAuction(Listing memory _targetListing) internal {
        require(
            listings[_targetListing.listingId].tokenOwner == _msgSender(),
            "EO15"
        );

        delete listings[_targetListing.listingId];
        delete exsist[_targetListing.assetContract][_targetListing.tokenId];

        transferListingTokens(
            address(this),
            _targetListing.tokenOwner,
            _targetListing.quantity,
            _targetListing
        );

        emit AuctionClosed(
            _targetListing.listingId,
            _targetListing.tokenHash,
            _msgSender(),
            true,
            _targetListing.tokenOwner,
            address(0)
        );
    }

    /// @dev Closes an auction for an auction creator; distributes winning bid amount to auction creator.
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

        payout(
            address(this),
            _targetListing.tokenOwner,
            _targetListing.currency,
            payoutAmount,
            _targetListing
        );

        delete exsist[_targetListing.assetContract][_targetListing.tokenId];

        emit AuctionClosed(
            _targetListing.listingId,
            _targetListing.tokenHash,
            _msgSender(),
            false,
            _targetListing.tokenOwner,
            _winningBid.offeror
        );
    }

    /// @dev Closes an auction for the winning bidder; distributes auction items to the winning bidder.
    function _closeAuctionForBidder(
        Listing memory _targetListing,
        Offer memory _winningBid
    ) internal {
        uint256 quantityToSend = _winningBid.quantityWanted;
       
        _targetListing.endTime = block.timestamp;
        _winningBid.quantityWanted = 0;

        winningBid[_targetListing.listingId] = _winningBid;
        listings[_targetListing.listingId] = _targetListing;

        

        transferListingTokens(
            address(this),
            _winningBid.offeror,
            quantityToSend,
            _targetListing
        );

        delete exsist[_targetListing.assetContract][_targetListing.tokenId];

        emit AuctionClosed(
            _targetListing.listingId,
            _targetListing.tokenHash,
            _msgSender(),
            false,
            _targetListing.tokenOwner,
            _winningBid.offeror
        );
    }

    /*///////////////////////////////////////////////////////////////
            Shared (direct+auction listings) internal functions
    //////////////////////////////////////////////////////////////*/

    function checkAlreadyListing(address assetContract,uint256 tokenId) internal view {
        ExsistListing memory check = exsist[assetContract][tokenId];
        require(!check.isExist,"EO16");
    }

    /// @dev Transfers tokens listed for sale in a direct or auction listing.
    function transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        Listing memory _listing
    ) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(_listing.assetContract).safeTransferFrom(
                _from,
                _to,
                _listing.tokenId,
                _quantity,
                ""
            );
        } else if (_listing.tokenType == TokenType.ERC721) {
            IERC721Upgradeable(_listing.assetContract).safeTransferFrom(
                _from,
                _to,
                _listing.tokenId,
                ""
            );
        }
    }

    /// @dev Pays out stakeholders in a sale.
    /// @dev remove platformfee for now.
    function payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Listing memory _listing
    ) internal {
        uint256 platformFeeCut = (_totalPayoutAmount * platformFeeBps) / MAX_BPS;

        uint256 royaltyCut = platformFeeCut;
        address royaltyRecipient = address(this);

        // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        try
            IERC2981Upgradeable(_listing.assetContract).royaltyInfo(
                _listing.tokenId,
                _totalPayoutAmount
            )
        returns (address royaltyFeeRecipient, uint256 royaltyFeeAmount) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                if(
                    // royaltyFeeAmount + platformFeeCut <= _totalPayoutAmount,
                    royaltyFeeAmount > _totalPayoutAmount
                ) {
                    revert RoyaltyExceedsPayout();
                }
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        // Distribute price to token owner
        address _nativeTokenWrapper = nativeTokenWrapper;

        // CurrencyTransferLib.transferCurrencyWithWrapper(
        //     _currencyToUse,
        //     _payer,
        //     platformFeeRecipient,
        //     platformFeeCut,
        //     _nativeTokenWrapper
        // );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            royaltyRecipient,
            royaltyCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            _payee,
            // _totalPayoutAmount - (platformFeeCut + royaltyCut),
            _totalPayoutAmount - royaltyCut,
            _nativeTokenWrapper
        );
    }

    /// @dev Validates that `_addrToCheck` owns and has approved markeplace to transfer the appropriate amount of currency
    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20Upgradeable(_currency).balanceOf(_addrToCheck) >=
                _currencyAmountToCheckAgainst &&
                IERC20Upgradeable(_currency).allowance(
                    _addrToCheck,
                    address(this)
                ) >=
                _currencyAmountToCheckAgainst,
            "EO18"
        );
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Market to transfer NFTs.
    function validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view {
        address market = address(this);
        bool isValid;

        if (_tokenType == TokenType.ERC1155) {
            isValid =
                IERC1155Upgradeable(_assetContract).balanceOf(
                    _tokenOwner,
                    _tokenId
                ) >=
                _quantity &&
                IERC1155Upgradeable(_assetContract).isApprovedForAll(
                    _tokenOwner,
                    market
                );
        } else if (_tokenType == TokenType.ERC721) {
            isValid =
                IERC721Upgradeable(_assetContract).ownerOf(_tokenId) ==
                _tokenOwner
                &&
                (IERC721Upgradeable(_assetContract).getApproved(_tokenId) ==
                    market ||
                    IERC721Upgradeable(_assetContract).isApprovedForAll(
                        _tokenOwner,
                        market
                    ));
        }

        require(isValid, "EO19");
    }

    /// @dev Validates conditions of a direct listing sale.
    function validateDirectListingSale(
        Listing memory _listing,
        address _payer,
        uint256 _quantityToBuy,
        address _currency,
        uint256 settledTotalPrice
    ) internal {
        require(
            _listing.listingType == ListingType.Direct,
            "EO20"
        );

        // Check whether a valid quantity of listed tokens is being bought.
        require(
            _listing.quantity > 0 &&
                _quantityToBuy > 0 &&
                _quantityToBuy <= _listing.quantity,
            "EO11"
        );

        // Check if sale is made within the listing window.
        if(
            block.timestamp > _listing.endTime ||
                block.timestamp < _listing.startTime){
                    revert ExpiredSale();
                }

        // Check: buyer owns and has approved sufficient currency for sale.
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value >= settledTotalPrice, "EO6");
        } else {
            validateERC20BalAndAllowance(_payer, _currency, settledTotalPrice);
        }

        // Check whether token owner owns and has approved `quantityToBuy` amount of listing tokens from the listing.
        validateOwnershipAndApproval(
            _listing.tokenOwner,
            _listing.assetContract,
            _listing.tokenId,
            _quantityToBuy,
            _listing.tokenType
        );
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE){
        uint256 balance = IERC20(nativeTokenWrapper).balanceOf(address(this));
        CurrencyTransferLib.transferCurrencyWithWrapper(
            tokenWrapper,
            address(this),
            platformFeeRecipient,
            balance,
            nativeTokenWrapper
        );
        
        
    }

    /*///////////////////////////////////////////////////////////////
                            Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Enforces quantity == 1 if tokenType is TokenType.ERC721.
    function getSafeQuantity(
        TokenType _tokenType,
        uint256 _quantityToCheck
    ) internal pure returns (uint256 safeQuantity) {
        if (_quantityToCheck == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721
                ? 1
                : _quantityToCheck;
        }
    }

    /// @dev Returns the interface supported by a contract.
    function getTokenType(
        address _assetContract
    ) internal view returns (TokenType tokenType) {
        if (
            IERC165Upgradeable(_assetContract).supportsInterface(
                type(IERC1155Upgradeable).interfaceId
            )
        ) {
            tokenType = TokenType.ERC1155;
        } else if (
            IERC165Upgradeable(_assetContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            tokenType = TokenType.ERC721;
        } else {
            revert();
        }
    }

    

    /*///////////////////////////////////////////////////////////////
                            Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin update platform fee recipient and bps.
    function setPlatformFee(
        address _platformFeeRecipient,
        uint256 _platformFeeBps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
       if(_platformFeeBps > MAX_BPS){
        revert ExceedsMaxBPS();
       }

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

    }

    /// @dev Lets a contract admin set auction buffers.
    function allowContract(
        address _contract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedContracts[_contract] = true;
    }

    /// @dev Lets a contract admin set auction buffers.
    function denieContract(
        address _contract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedContracts[_contract] = false;
    }

    /// @dev Lets a contract admin set listing fee.
    /*
    function setListingFee(
        uint256 _listingFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        listingFee = _listingFee;

        emit ListingFeeUpdated(_listingFee);
    }*/

    /// @dev Lets a contract admin set auction buffers.
    function setAuctionBuffers(
        uint256 _timeBuffer,
        uint256 _bidBufferBps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(_bidBufferBps > MAX_BPS) {
            revert ExceedsMaxBPS();
        }

        timeBuffer = uint64(_timeBuffer);
        bidBufferBps = uint64(_bidBufferBps);

        
    }
    function setNativeTokenWrapper(address _token) external onlyRole(DEFAULT_ADMIN_ROLE){
        nativeTokenWrapper = _token;
    }



    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}