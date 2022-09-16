// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IAffiliate.sol";

interface IAddressRegistry {
    function affiliate() external view returns (address);

    function auction() external view returns (address);

    function tokenRegistry() external view returns (address);

    function priceFeed() external view returns (address);
}

interface IAuction {
    function auctions(address, uint256)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            bool
        );
}

interface ITokenRegistry {
    function enabled(address) external view returns (bool);
}

interface IPriceFeed {
    function wrappedToken() external view returns (address);

    function getPrice(address) external view returns (int256, uint8);
}

interface IERC721Ownable {
    function owner() external view returns (address);
}

contract Marketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20 for IERC20;

    /// @notice Events for the contract
    event ItemListed(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem,
        uint256 startingTime
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        int256 unitPrice,
        uint256 pricePerItem
    );
    event ItemUpdated(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 newPrice
    );
    event ItemCanceled(
        address indexed owner,
        address indexed nft,
        uint256 tokenId
    );
    event OfferCreated(
        address indexed creator,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem,
        uint256 deadline
    );
    event OfferCanceled(
        address indexed creator,
        address indexed nft,
        uint256 tokenId
    );
    event UpdatePlatformFee(uint16 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);

    /// @notice Structure for listed items
    struct Listing {
        uint256 quantity;
        address payToken;
        uint256 pricePerItem;
        uint256 startingTime;
    }

    /// @notice Structure for offer
    struct Offer {
        IERC20 payToken;
        uint256 quantity;
        uint256 pricePerItem;
        uint256 deadline;
    }

    struct CollectionRoyalty {
        uint16 royalty;
        address creator;
        address feeRecipient;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice NftAddress -> Token ID -> Minter
    mapping(address => mapping(uint256 => address)) public minters;

    /// @notice NftAddress -> Token ID -> Royalty
    mapping(address => mapping(uint256 => uint16)) public royalties;

    /// @notice NftAddress -> Token ID -> Owner -> Listing item
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public listings;

    /// @notice NftAddress -> Token ID -> Offerer -> Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public offers;

    /// @notice Platform fee
    uint16 public platformFee;

    /// @notice Platform fee receipient
    address payable public feeReceipient;

    /// @notice NftAddress -> Royalty
    mapping(address => CollectionRoyalty) public collectionRoyalties;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    /// @notice Checks if an item is listed
    modifier isListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listing = listings[_nftAddress][_tokenId][_owner];
        require(listing.quantity > 0, "not listed item");
        _;
    }

    /// @notice Checks if an item is not listed
    modifier notListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listing = listings[_nftAddress][_tokenId][_owner];
        require(listing.quantity == 0, "already listed");
        _;
    }

    /// @notice Validates listing, checks for valid owner and starting time
    modifier validListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        _validOwner(_nftAddress, _tokenId, _owner);

        require(_getNow() >= listedItem.startingTime, "item not buyable");
        _;
    }

    /// @notice Checks if offer exists
    modifier offerExists(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];
        require(
            offer.quantity > 0 && offer.deadline > _getNow(),
            "offer not exists or expired"
        );
        _;
    }
    /// @notice Checks if offer does not exist
    modifier offerNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];
        require(
            offer.quantity == 0 || offer.deadline <= _getNow(),
            "offer already created"
        );
        _;
    }

    /// @notice Contract initializer
    /// @param _feeRecipient Address of the fee recipient
    /// @param _platformFee Fee of the platform
    function initialize(address payable _feeRecipient, uint16 _platformFee)
        public
        initializer
    {
        platformFee = _platformFee;
        feeReceipient = _feeRecipient;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Method for listing NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _payToken Paying token
    /// @param _pricePerItem sale price for each iteam
    /// @param _startingTime scheduling for a future sale
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _pricePerItem,
        uint256 _startingTime
    ) external notListed(_nftAddress, _tokenId, _msgSender()) {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "not owning item");
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "item not approved"
            );
        } else {
            revert("invalid nft address");
        }

        _validPayToken(_payToken);

        listings[_nftAddress][_tokenId][_msgSender()] = Listing(
            _quantity,
            _payToken,
            _pricePerItem,
            _startingTime
        );
        emit ItemListed(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _payToken,
            _pricePerItem,
            _startingTime
        );
    }

    /// @notice Method for canceling listed NFT
    /// @param _nftAddress Address of the NFT contract
    /// @param _tokenId Id of the token
    function cancelListing(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        isListed(_nftAddress, _tokenId, _msgSender())
    {
        _cancelListing(_nftAddress, _tokenId, _msgSender());
    }

    /// @notice Method for updating listed NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _payToken payment token
    /// @param _newPrice New sale price for each iteam
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice
    ) external nonReentrant isListed(_nftAddress, _tokenId, _msgSender()) {
        Listing storage listedItem = listings[_nftAddress][_tokenId][
            _msgSender()
        ];

        _validOwner(_nftAddress, _tokenId, _msgSender());

        _validPayToken(_payToken);

        listedItem.payToken = _payToken;
        listedItem.pricePerItem = _newPrice;
        emit ItemUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _newPrice
        );
    }

    /// @notice Method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Address of the payment token, must match registered pay token
    /// @param _owner owner of the token
    /// @param _affiliateOwner For establishing referral connections
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner,
        address _affiliateOwner
    )
        external
        payable
        nonReentrant
        isListed(_nftAddress, _tokenId, _owner)
        validListing(_nftAddress, _tokenId, _owner)
    {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        require(listedItem.payToken == _payToken, "invalid pay token");
        IAffiliate(addressRegistry.affiliate()).signUpWithPromo(
            msg.sender,
            _affiliateOwner
        );
        _buyItem(_nftAddress, _tokenId, _payToken, _owner);
    }

    /// @dev Private Method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Address of the payment token, must match registered pay token
    /// @param _owner owner of the token
    function _buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner
    ) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        uint256 price = listedItem.pricePerItem * listedItem.quantity;

        uint256 platformFeeAmount = (price * platformFee) / (1e4);

        IAffiliate(addressRegistry.affiliate()).setHasTransacted(_owner);
        IAffiliate(addressRegistry.affiliate()).setHasTransacted(_msgSender());

        uint256 royaltyFee;

        address minter = collectionRoyalties[_nftAddress].feeRecipient;
        uint16 royalty = collectionRoyalties[_nftAddress].royalty;
        if (minter != address(0) && royalty != 0) {
            royaltyFee = ((price - platformFeeAmount) * royalty) / 10000;

            if (listedItem.payToken == address(0)) {
                (bool transferToAffiliateContract, ) = payable(
                    addressRegistry.affiliate()
                ).call{value: royaltyFee}("");
                require(transferToAffiliateContract, "transfer failed");
                IAffiliate(addressRegistry.affiliate())
                    .splitFeeWithAffiliateETH(
                        royaltyFee,
                        _msgSender(),
                        minter,
                        platformFeeAmount
                    );
            } else {
                IAffiliate(addressRegistry.affiliate()).splitFeeWithAffiliate(
                    IERC20(listedItem.payToken),
                    royaltyFee,
                    _msgSender(),
                    _msgSender(),
                    minter,
                    platformFeeAmount
                );
            }
        }
        if (royaltyFee == 0) {
            if (listedItem.payToken == address(0)) {
                (bool transferToAffiliateContract, ) = payable(
                    addressRegistry.affiliate()
                ).call{value: platformFeeAmount}("");
                require(transferToAffiliateContract, "transfer failed");
                IAffiliate(addressRegistry.affiliate())
                    .splitFeeWithAffiliateETH(
                        platformFeeAmount,
                        _msgSender(),
                        feeReceipient,
                        platformFeeAmount
                    );
            } else {
                IAffiliate(addressRegistry.affiliate()).splitFeeWithAffiliate(
                    IERC20(_payToken),
                    platformFeeAmount,
                    _msgSender(),
                    _msgSender(),
                    feeReceipient,
                    platformFeeAmount
                );
            }
        } else {
            //Referral fee has already been taken care of, so just send the platform fee to the platform fee recipient
            if (listedItem.payToken == address(0)) {
                (bool transferToAffiliateContract, ) = payable(feeReceipient)
                    .call{value: platformFeeAmount}("");
                require(transferToAffiliateContract, "transfer failed");
            } else {
                IERC20(_payToken).safeTransferFrom(
                    _msgSender(),
                    feeReceipient,
                    platformFeeAmount
                );
            }
        }
        if (listedItem.payToken == address(0)) {
            (bool transferToOwner, ) = payable(_owner).call{
                value: price - platformFeeAmount - royaltyFee
            }("");
            require(transferToOwner, "transfer failed");
        } else {
            IERC20(_payToken).safeTransferFrom(
                _msgSender(),
                _owner,
                price - platformFeeAmount - royaltyFee
            );
        }

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId
            );
        }

        emit ItemSold(
            _owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            listedItem.quantity,
            _payToken,
            getPrice(_payToken),
            price / listedItem.quantity
        );
        delete (listings[_nftAddress][_tokenId][_owner]);
    }

    /// @notice Method for offering item
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Paying token
    /// @param _quantity Quantity of items
    /// @param _pricePerItem Price per item
    /// @param _deadline Offer expiration
    /// @param _affiliateOwner For establishing referral connections
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        IERC20 _payToken,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _deadline,
        address _affiliateOwner
    ) external offerNotExists(_nftAddress, _tokenId, _msgSender()) {
        require(
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721),
            "invalid nft address"
        );

        IAuction auction = IAuction(addressRegistry.auction());

        (address owner, , , , bool resulted) = auction.auctions(
            _nftAddress,
            _tokenId
        );

        require(
            owner == address(0) || resulted == true,
            "cannot place an offer if auction is going on"
        );

        require(_deadline > _getNow(), "invalid expiration");

        IAffiliate(addressRegistry.affiliate()).signUpWithPromo(
            msg.sender,
            _affiliateOwner
        );
        _createOffer(
            _nftAddress,
            _tokenId,
            _payToken,
            _quantity,
            _pricePerItem,
            _deadline
        );
    }

    /// @dev Private Method for offering item
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Paying token
    /// @param _quantity Quantity of items
    /// @param _pricePerItem Price per item
    /// @param _deadline Offer expiration
    function _createOffer(
        address _nftAddress,
        uint256 _tokenId,
        IERC20 _payToken,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _deadline
    ) private {
        _validPayToken(address(_payToken));

        offers[_nftAddress][_tokenId][_msgSender()] = Offer(
            _payToken,
            _quantity,
            _pricePerItem,
            _deadline
        );

        emit OfferCreated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            address(_payToken),
            _pricePerItem,
            _deadline
        );
    }

    /// @notice Method for canceling the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function cancelOffer(address _nftAddress, uint256 _tokenId)
        external
        offerExists(_nftAddress, _tokenId, _msgSender())
    {
        delete (offers[_nftAddress][_tokenId][_msgSender()]);
        emit OfferCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /// @notice Method for accepting the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _creator Offer creator address
    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external nonReentrant offerExists(_nftAddress, _tokenId, _creator) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];

        _validOwner(_nftAddress, _tokenId, _msgSender());

        uint256 price = offer.pricePerItem * offer.quantity;
        uint256 platformFeeAmount = (price * platformFee) / 1e4;

        IAffiliate(addressRegistry.affiliate()).setHasTransacted(_creator);
        IAffiliate(addressRegistry.affiliate()).setHasTransacted(_msgSender());

        uint256 royaltyFee;

        address minter = collectionRoyalties[_nftAddress].feeRecipient;
        uint16 royalty = collectionRoyalties[_nftAddress].royalty;
        if (minter != address(0) && royalty != 0) {
            royaltyFee = ((price - platformFeeAmount) * royalty) / 10000;
            IAffiliate(addressRegistry.affiliate()).splitFeeWithAffiliate(
                offer.payToken,
                royaltyFee,
                _creator,
                _creator,
                minter,
                platformFeeAmount
            );
        }

        if (royaltyFee == 0) {
            //If there is no royalty fee, split referral fee using platform fee
            IAffiliate(addressRegistry.affiliate()).splitFeeWithAffiliate(
                offer.payToken,
                platformFeeAmount,
                _creator,
                _creator,
                feeReceipient,
                platformFeeAmount
            );
        } else {
            //Referral fee has already been taken care of, so just send the platform fee to the platform fee recipient
            offer.payToken.safeTransferFrom(
                _creator,
                feeReceipient,
                platformFeeAmount
            );
        }

        offer.payToken.safeTransferFrom(
            _creator,
            _msgSender(),
            price - platformFeeAmount
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId
            );
        }

        emit ItemSold(
            _msgSender(),
            _creator,
            _nftAddress,
            _tokenId,
            offer.quantity,
            address(offer.payToken),
            getPrice(address(offer.payToken)),
            offer.pricePerItem
        );

        emit OfferCanceled(_creator, _nftAddress, _tokenId);

        delete (listings[_nftAddress][_tokenId][_msgSender()]);
        delete (offers[_nftAddress][_tokenId][_creator]);
    }

    /// @notice Method for setting royalty
    /// @param _nftAddress NFT contract address
    /// @param _royalty Royalty
    function registerCollectionRoyalty(
        address _nftAddress,
        address _creator,
        uint16 _royalty,
        address _feeRecipient
    ) external {
        require(_creator != address(0), "invalid creator address");
        require(_royalty <= 1000, "Max royalty is 10%");
        require(_feeRecipient != address(0), "invalid fee recipient address");

        address collectionOwner = IERC721Ownable(_nftAddress).owner();

        require(
            _msgSender() == collectionOwner,
            "Caller must be collection owner"
        );

        if (collectionRoyalties[_nftAddress].creator == address(0)) {
            collectionRoyalties[_nftAddress] = CollectionRoyalty(
                _royalty,
                _creator,
                _feeRecipient
            );
        } else {
            CollectionRoyalty storage collectionRoyalty = collectionRoyalties[
                _nftAddress
            ];

            collectionRoyalty.royalty = _royalty;
            collectionRoyalty.feeRecipient = _feeRecipient;
            collectionRoyalty.creator = _creator;
        }
    }

    /**
     @notice Method for getting price for pay token
     @param _payToken Paying token
     */
    function getPrice(address _payToken) public view returns (int256) {
        int256 unitPrice;
        uint8 decimals;
        IPriceFeed priceFeed = IPriceFeed(addressRegistry.priceFeed());

        if (_payToken == address(0)) {
            (unitPrice, decimals) = priceFeed.getPrice(
                priceFeed.wrappedToken()
            );
        } else {
            (unitPrice, decimals) = priceFeed.getPrice(_payToken);
        }
        if (decimals < 18) {
            unitPrice = unitPrice * (int256(10)**(18 - decimals));
        } else {
            unitPrice = unitPrice / (int256(10)**(decimals - 18));
        }

        return unitPrice;
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint16 the platform fee to set
     */
    function updatePlatformFee(uint16 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external
        onlyOwner
    {
        feeReceipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Update AddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IAddressRegistry(_registry);
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    /// @dev Function to get current block timestamp
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Verify if the chosen pay token is in the token registry
    function _validPayToken(address _payToken) internal view {
        require(
            _payToken == address(0) ||
                (addressRegistry.tokenRegistry() != address(0) &&
                    ITokenRegistry(addressRegistry.tokenRegistry()).enabled(
                        _payToken
                    )),
            "invalid pay token"
        );
    }

    /// @dev Verify the token id and owner matches
    function _validOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) internal view {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "not owning item");
        } else {
            revert("invalid nft address");
        }
    }

    /// @dev Cancels the listing
    function _cancelListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) private {
        _validOwner(_nftAddress, _tokenId, _owner);

        delete (listings[_nftAddress][_tokenId][_owner]);
        emit ItemCanceled(_owner, _nftAddress, _tokenId);
    }

    /**
     @notice Method for fetching the royalty recipient of a collection - used in Marketplace to determine referral payment logic to avoid stack too deep error
     */
    function getCollectionRoyaltyFeeRecipient(address _nft_address)
        public
        view
        returns (address)
    {
        return collectionRoyalties[_nft_address].feeRecipient;
    }

    /**
     @notice Method for fetching the royalty rate of a collection - used in Marketplace to determine referral payment logic to avoid stack too deep error
     */
    function getCollectionRoyaltyRoyalty(address _nft_address)
        public
        view
        returns (uint16)
    {
        return collectionRoyalties[_nft_address].royalty;
    }
}