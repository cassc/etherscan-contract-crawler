// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PoxiMarketplaceV1 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
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
        uint256 startingTime,
        address referrer
    );

    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem,
        address referrer
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

    event ReferralFeeSet(address indexed referrer, uint24 fee);

    event UpdatePlatformFee(uint24 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);

    event TokenAddedToAllowlist(address token);
    event TokenRemovedFromAllowlist(address token);

    /// @notice Structure for listed items
    struct Listing {
        uint256 quantity;
        address payToken;
        uint256 pricePerItem;
        uint256 startingTime;
        address referrer;
    }

    /// @notice Structure for offer
    struct Offer {
        IERC20 payToken;
        uint256 quantity;
        uint256 pricePerItem;
        uint256 deadline;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice NftAddress -> Token ID -> Owner -> Listing item
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public listings;

    /// @notice NftAddress -> Token ID -> Offerer -> Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public offers;

    /// @notice Token allowlist
    mapping(address => bool) public tokenAllowlist;

    /// @notice Referrer -> Referrer fee
    mapping (address => uint24) public referrerFees;

    /// @notice Platform fee
    uint24 public platformFee;

    /// @notice Platform fee recipient
    address payable public feeRecipient;

    modifier isListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        require(listings[_nftAddress][_tokenId][_owner].quantity > 0, "Item not listed");
        _;
    }

    modifier notListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        require(listings[_nftAddress][_tokenId][_owner].quantity == 0, "Item already listed");
        _;
    }

    modifier validListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        _assertValidOwner(_nftAddress, _tokenId, _owner, listedItem.quantity);

        require(_getNow() >= listedItem.startingTime, "Item not buyable");
        _;
    }

    modifier offerExists(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) {
        require(offers[_nftAddress][_tokenId][_creator].quantity > 0, "Offer doesn't exist");
        require(offers[_nftAddress][_tokenId][_creator].deadline > _getNow(), "Offer expired");
        _;
    }

    modifier offerNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];
        require(
            offer.quantity == 0 || offer.deadline <= _getNow(),
            "Offer already created"
        );
        _;
    }

    modifier onlyTokenInAllowlist(address _token) {
        require(tokenAllowlist[_token], "Token not in allowlist");
        _;
    }

    modifier quantityNotZero(uint256 _quantity) {
        require(_quantity > 0, "Quantity must be greater than 0");
        _;
    }

    /**
     * @notice Modifier to check if fee is under 10%, this is to prevent owner from setting a fee that is too high 
     */
    modifier feeUnder10pct(uint24 _fee) {
        require(_fee <= 10_000, "Fee must be under 10% (1000 mpb)");
        _;
    }

    /// @notice Contract initializer
    function initialize(address payable _feeRecipient, uint24 _platformFee)
        public
        initializer
        feeUnder10pct(_platformFee)
    {
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Method for listing NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _payToken ERC-20 token address to pay with
    /// @param _pricePerItem sale price for each iteam
    /// @param _startingTime scheduling for a future sale
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _pricePerItem,
        uint256 _startingTime,
        address _referrer
    )
        external
        notListed(_nftAddress, _tokenId, _msgSender())
        onlyTokenInAllowlist(_payToken)
        quantityNotZero(_quantity)
    {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "Not token owner");
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "Item not approved"
            );
            require(_quantity == 1, "Invalid quantity, must be 1");
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= _quantity,
                "Must hold enough NFTs"
            );
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "Item not approved"
            );
        } else {
            revert("Invalid NFT address");
        }

        listings[_nftAddress][_tokenId][_msgSender()] = Listing(
            _quantity,
            _payToken,
            _pricePerItem,
            _startingTime,
            _referrer
        );

        emit ItemListed(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _payToken,
            _pricePerItem,
            _startingTime,
            _referrer
        );
    }

    /// @notice Method for canceling listed NFT
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
    )
        external
        nonReentrant
        isListed(_nftAddress, _tokenId, _msgSender())
        onlyTokenInAllowlist(_payToken)
    {
        Listing storage listedItem = listings[_nftAddress][_tokenId][
            _msgSender()
        ];

        _assertValidOwner(
            _nftAddress,
            _tokenId,
            _msgSender(),
            listedItem.quantity
        );

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
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner
    )
        external
        nonReentrant
        isListed(_nftAddress, _tokenId, _owner)
        validListing(_nftAddress, _tokenId, _owner)
    {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        require(listedItem.payToken == _payToken, "Invalid pay token");

        _buyItem(_nftAddress, _tokenId, _payToken, _owner);
    }

    function _buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner
    ) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        uint256 price = listedItem.pricePerItem.mul(listedItem.quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e5);
        uint256 referrerFeeAmount = 0;

        if (listedItem.referrer != address(0)) {
            uint256 referrerFee = referrerFees[listedItem.referrer];
            if (referrerFee == 0) {
                referrerFee = referrerFees[address(0)];
            }

            referrerFeeAmount = feeAmount.mul(referrerFee).div(1e5);
            
            IERC20(_payToken).safeTransferFrom(
                _msgSender(),
                listedItem.referrer,
                referrerFeeAmount
            );
        }

        IERC20(_payToken).safeTransferFrom(
            _msgSender(),
            feeRecipient,
            feeAmount.sub(referrerFeeAmount)
        );

        IERC20(_payToken).safeTransferFrom(
            _msgSender(),
            _owner,
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId,
                listedItem.quantity,
                bytes("")
            );
        }

        emit ItemSold(
            _owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            listedItem.quantity,
            _payToken,
            price.div(listedItem.quantity),
            listedItem.referrer
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
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        IERC20 _payToken,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _deadline
    )
        external
        offerNotExists(_nftAddress, _tokenId, _msgSender())
        onlyTokenInAllowlist(address(_payToken))
        quantityNotZero(_quantity)
    {
        if(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            require(_quantity == 1, "Invalid quantity, must be 1");
        } else if (!IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            revert("Invalid NFT address");
        }

        require(_deadline > _getNow(), "Deadline is in the past");

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
        address _creator,
        address _referrer
    ) external nonReentrant offerExists(_nftAddress, _tokenId, _creator) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];

        _assertValidOwner(_nftAddress, _tokenId, _msgSender(), offer.quantity);

        uint256 price = offer.pricePerItem.mul(offer.quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e5);
        uint256 referrerFeeAmount = 0;
        
        if (_referrer != address(0)) {
            uint256 referrerFee = referrerFees[_referrer];
            if (referrerFee == 0) {
                referrerFee = referrerFees[address(0)];
            }

            referrerFeeAmount = feeAmount.mul(referrerFee).div(1e5);
            
            offer.payToken.safeTransferFrom(
                _creator,
                _referrer,
                referrerFeeAmount
            );
        }

        offer.payToken.safeTransferFrom(_creator, feeRecipient, feeAmount.sub(referrerFeeAmount));

        offer.payToken.safeTransferFrom(
            _creator,
            _msgSender(),
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId,
                offer.quantity,
                bytes("")
            );
        }

        emit ItemSold(
            _msgSender(),
            _creator,
            _nftAddress,
            _tokenId,
            offer.quantity,
            address(offer.payToken),
            offer.pricePerItem,
            _referrer
        );

        emit OfferCanceled(_creator, _nftAddress, _tokenId);

        delete (listings[_nftAddress][_tokenId][_msgSender()]);
        delete (offers[_nftAddress][_tokenId][_creator]);
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint24 the platform fee to set
     */
    function updatePlatformFee(uint24 _platformFee) external onlyOwner feeUnder10pct(_platformFee) {
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
        feeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     * @notice Adds a single ERC-20 token address to the allowlist.
     * @dev Only the contract owner can call this method.
     * @param _token address of the token to add to the allowlist. Must be ERC-20 contract address
     */
    function addTokenToAllowlist(address _token) external onlyOwner {
        tokenAllowlist[_token] = true;
        emit TokenAddedToAllowlist(_token);
    }

    /**
     * @notice Adds a list of ERC-20 token addresses to the allowlist.
     * @dev Only the contract owner can call this method.
     * @param _tokens the array of addresses to add to the allowlist. Must be ERC-20 contract addresses
     */
    function addMultipleTokensToAllowlist(address[] memory _tokens) external onlyOwner {
        for (uint16 i = 0; i < _tokens.length; i++) {
            tokenAllowlist[_tokens[i]] = true;
            emit TokenAddedToAllowlist(_tokens[i]);
        }
    }

    /**
     * @notice Removes a single ERC-20 token address from allowlist.
     * @dev Only the contract owner can call this method.
     * @param _token address to remove from the allowlist
     */
    function removeTokenFromAllowlist(address _token) external onlyOwner {
        require(tokenAllowlist[_token], "Token not in allowlist");
        tokenAllowlist[_token] = false;
        emit TokenRemovedFromAllowlist(_token);
    }

    /**
     * @notice set the referral fee for the given referrer. Must be in basis points (100% is 100 000)
     */
    function setReferralFee(address _referrer, uint24 _fee) external onlyOwner {
        require (_fee <= 100_000, "Fee must be <= 100% (100 000 mpb)");
        referrerFees[_referrer] = _fee;
        emit ReferralFeeSet(_referrer, _fee);
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _assertValidOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        uint256 quantity
    ) internal view {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            require(IERC721(_nftAddress).ownerOf(_tokenId) == _owner, "Not token owner");
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            require(
                IERC1155(_nftAddress).balanceOf(_owner, _tokenId) >= quantity,
                "Not token owner"
            );
        } else {
            revert("Invalid nft address");
        }
    }

    function _cancelListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        _assertValidOwner(_nftAddress, _tokenId, _owner, listedItem.quantity);

        delete (listings[_nftAddress][_tokenId][_owner]);
        emit ItemCanceled(_owner, _nftAddress, _tokenId);
    }
}