// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Mintable.sol";
import "./libraries/ERC721MarketplaceHelper.sol";

contract UPYOERC721MarketPlaceV6 is
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Storage

    //auction type :
    // 1 : only direct buy
    // 2 : only bid

    struct auction {
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store auction details
    mapping(address => mapping(uint256 => auction)) _auctions;

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // address to transfer brokerage
    address payable public broker;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // Mapping to manage nonce for lazy mint
    mapping(address => mapping(uint256 => bool)) public isNonceProcessed;

    // Platform's signer address
    address _signer;

    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingCharge;

    // WETH address
    address public WETH;

    // Mapping to store nonce status.
    mapping(uint256 => bool) public auctionNonceStatus;

    // offer nonce
    mapping(uint256 => bool) isOfferNonceProcessed;

    struct sellerVoucher {
        address to;
        uint96 royalty;
        string tokenURI;
        uint256 nonce;
        address erc721;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 endingTime;
        address erc20Token;
    }

    struct buyerVoucher {
        address buyer;
        uint256 amount;
        uint256 time;
    }

    struct lazySellerVoucher {
        address to;
        uint96 royalty;
        string tokenURI;
        uint256 nonce;
        address erc721;
        uint256 price;
        address erc20Token;
        bytes sign;
    }

    struct bidInput {
        uint256 _tokenId;
        address _erc721;
        uint256 amount;
        address payable bidder;
        uint256 _nonce;
        bytes sign;
        bytes32 root;
        bytes32[] proof;
    }

    mapping(bytes32 => bool) public isRootDiscarded;

    // Events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        address collector,
        uint256 auctionType,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        uint256 nonce
    );
    event LazyAuction(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address ERC20Address,
        uint256 price,
        uint256 time
    );
    event LazyMinted(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address ERC20Address,
        uint256 price,
        uint256 time
    );
    event OfferAccepted(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event LazyOfferAccepted(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC721Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier onSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).seller != address(0),
            "ERC721Marketplace: Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 _tokenId, address _erc721) {
        require(
            block.timestamp < auctions(_erc721, _tokenId).closingTime,
            "ERC721Marketplace: Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 2,
            "ERC721Marketplace: Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 1,
            "ERC721Marketplace: Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId, address _erc721) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IERC721Mintable(_erc721).ownerOf(_tokenId) == msg.sender,
            "ERC721Marketplace: You must be owner and Token should not have any bid"
        );
        _;
    }

    modifier rootActive(bytes32 root) {
        require(!isRootDiscarded[root], "ERC721Marketplace: Root Discarded.");
        _;
    }

    // Getters
    function auctions(address _erc721, uint256 _tokenId)
        public
        view
        returns (auction memory)
    {
        address _owner = IERC721Mintable(_erc721).ownerOf(_tokenId);
        if (
            _owner == _auctions[_erc721][_tokenId].seller ||
            _owner == address(this)
        ) {
            return _auctions[_erc721][_tokenId];
        }
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function setSigner(address signer_) external onlyOwner {
        require(
            signer_ != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        _signer = signer_;
    }

    function setWETH(address _WETH) external onlyOwner {
        require(
            _WETH != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        WETH = _WETH;
    }

    function signer() external view onlyOwner returns (address) {
        return _signer;
    }

    // Method to set minting charges per NFT
    function setMintingCharge(uint256 _mintingCharge) external onlyOwner {
        mintingCharge = _mintingCharge;
    }

    function bid(
        uint256 _tokenId,
        address _erc721,
        uint256 amount,
        address payable bidder,
        auction memory _auction,
        uint256 _nonce,
        bytes calldata sign
    ) external payable nonReentrant {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        {
            address seller = Token.ownerOf(_tokenId);

            if (auctionNonceStatus[_nonce]) {
                _auction = _auctions[_erc721][_tokenId];
                require(
                    _auction.seller != address(0) &&
                        (seller == _auction.seller || seller == address(this)),
                    "ERC721Marketplace: Token Not For Sale"
                );
            } else {
                ERC721MarketplaceHelper.validateBidSign(
                    _auction,
                    _erc721,
                    _tokenId,
                    _nonce,
                    seller,
                    sign
                );

                _auction.currentBid =
                    _auction.startingPrice +
                    (brokerage[_auction.erc20Token].buyer *
                        _auction.startingPrice) /
                    (100 * decimalPrecision);
                _auction.auctionType = 2;
            }
            require(
                block.timestamp >= _auction.startingTime &&
                    block.timestamp <= _auction.closingTime,
                "ERC721Marketplace: Auction Time Over!"
            );
            auctionNonceStatus[_nonce] = true;
        }

        _auctions[_erc721][_tokenId] = ERC721MarketplaceHelper.handleBidFund(
            _auction,
            amount,
            Token,
            _tokenId,
            bidder
        );

        // Bid event
        emit Bid(
            _erc721,
            _tokenId,
            _auctions[_erc721][_tokenId].seller,
            _auctions[_erc721][_tokenId].highestBidder,
            _auctions[_erc721][_tokenId].currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function bidBatch(
        auction memory _auction,
        bidInput calldata _bidInput
    ) external payable nonReentrant rootActive(_bidInput.root) {
        IERC721Mintable Token = IERC721Mintable(_bidInput._erc721);
        {
            address seller = Token.ownerOf(_bidInput._tokenId);

            if (auctionNonceStatus[_bidInput._nonce]) {
                _auction = _auctions[_bidInput._erc721][_bidInput._tokenId];
                require(
                    _auction.seller != address(0) &&
                        (seller == _auction.seller || seller == address(this)),
                    "ERC721Marketplace: Token Not For Sale"
                );
            } else {
                ERC721MarketplaceHelper.validateBidSignBatch(
                    _auction,
                    _bidInput,
                    seller
                );

                _auction.currentBid =
                    _auction.startingPrice +
                    (brokerage[_auction.erc20Token].buyer *
                        _auction.startingPrice) /
                    (100 * decimalPrecision);
                _auction.auctionType = 2;
            }
            require(
                block.timestamp >= _auction.startingTime &&
                    block.timestamp <= _auction.closingTime,
                "ERC721Marketplace: Auction Time Over!"
            );
            auctionNonceStatus[_bidInput._nonce] = true;
        }

        _auctions[_bidInput._erc721][
            _bidInput._tokenId
        ] = ERC721MarketplaceHelper.handleBidFund(
            _auction,
            _bidInput.amount,
            Token,
            _bidInput._tokenId,
            _bidInput.bidder
        );

        // Bid event
        emit Bid(
            _bidInput._erc721,
            _bidInput._tokenId,
            _auctions[_bidInput._erc721][_bidInput._tokenId].seller,
            _auctions[_bidInput._erc721][_bidInput._tokenId].highestBidder,
            _auctions[_bidInput._erc721][_bidInput._tokenId].currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function _getCreatorAndRoyalty(
        address _erc721,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(_erc721);

        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 _tokenId, address _erc721)
        external
        onSaleOnly(_tokenId, _erc721)
        auctionOnly(_tokenId, _erc721)
        nonReentrant
    {
        auction memory _auction = _auctions[_erc721][_tokenId];

        _brokerage memory brokerage_;

        brokerage_.seller =
            (brokerage[_auction.erc20Token].seller * _auction.currentBid) /
            (100 * decimalPrecision);

        // Calculate Brokerage
        brokerage_.buyer =
            (brokerage[_auction.erc20Token].buyer * _auction.currentBid) /
            (100 * decimalPrecision);

        ERC721MarketplaceHelper.handleCollect(
            _tokenId,
            _erc721,
            _auction,
            brokerage_,
            broker
        );

        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.highestBidder,
            _auction.currentBid - brokerage_.buyer,
            msg.sender,
            _auction.auctionType,
            block.timestamp,
            _auction.erc20Token
        );
        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function buy(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        address buyer
    ) external payable nonReentrant {
        require(
            !auctionNonceStatus[_nonce],
            "ERC721Marketplace: Nonce have been already processed."
        );

        address seller = IERC721Mintable(_erc721).ownerOf(_tokenId);

        ERC721MarketplaceHelper.validateBuy(
            _tokenId,
            _erc721,
            price,
            _nonce,
            sign,
            _erc20Token,
            seller
        );

        _brokerage memory brokerage_;

        brokerage_.seller =
            (brokerage[_erc20Token].seller * price) /
            (100 * decimalPrecision);

        // Calculate Brokerage
        brokerage_.buyer =
            (brokerage[_erc20Token].buyer * price) /
            (100 * decimalPrecision);

        ERC721MarketplaceHelper.handleBuy(
            _tokenId,
            _erc721,
            price,
            _erc20Token,
            buyer,
            brokerage_,
            broker,
            seller
        );

        auctionNonceStatus[_nonce] = true;
        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            seller,
            buyer,
            price,
            buyer,
            1,
            block.timestamp,
            _erc20Token
        );

        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function buyBatch(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        address buyer,
        bytes32 root,
        bytes32[] calldata proof
    ) external payable nonReentrant rootActive(root) {
        require(
            !auctionNonceStatus[_nonce],
            "ERC721Marketplace: Nonce have been already processed."
        );

        address seller = IERC721Mintable(_erc721).ownerOf(_tokenId);

        ERC721MarketplaceHelper.validateBuyBatch(
            _tokenId,
            _erc721,
            price,
            _nonce,
            sign,
            _erc20Token,
            seller,
            root,
            proof
        );
        {
            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_erc20Token].seller * price) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_erc20Token].buyer * price) /
                (100 * decimalPrecision);

            ERC721MarketplaceHelper.handleBuy(
                _tokenId,
                _erc721,
                price,
                _erc20Token,
                buyer,
                brokerage_,
                broker,
                seller
            );
        }
        auctionNonceStatus[_nonce] = true;
        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            seller,
            buyer,
            price,
            buyer,
            1,
            block.timestamp,
            _erc20Token
        );

        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    function putSaleOff(
        uint256 _tokenId,
        address _erc721,
        uint256 _nonce
    ) external tokenOwnerOnly(_tokenId, _erc721) {
        auctionNonceStatus[_nonce] = true;

        // OffSale event
        emit OffSale(_erc721, _tokenId, msg.sender, block.timestamp, _nonce);
        delete _auctions[_erc721][_tokenId];
    }

    function discardRootWithBuy(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        bytes32 root,
        bytes32[] calldata proof
    ) external tokenOwnerOnly(_tokenId, _erc721) {
        require(
            !auctionNonceStatus[_nonce],
            "ERC721Marketplace: Nonce have been already processed."
        );

        address seller = IERC721Mintable(_erc721).ownerOf(_tokenId);

        ERC721MarketplaceHelper.validateBuyBatch(
            _tokenId,
            _erc721,
            price,
            _nonce,
            sign,
            _erc20Token,
            seller,
            root,
            proof
        );
        isRootDiscarded[root] = true;
    }

    function discardRootWithBid(
        auction memory _auction,
        bidInput calldata _bidInput
    ) external tokenOwnerOnly(_bidInput._tokenId, _bidInput._erc721) {
        address seller = IERC721Mintable(_bidInput._erc721).ownerOf(
            _bidInput._tokenId
        );
        ERC721MarketplaceHelper.validateBidSignBatch(
            _auction,
            _bidInput,
            seller
        );

        isRootDiscarded[_bidInput.root] = true;
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function lazyMintAuction(
        sellerVoucher memory _sellerVoucher,
        buyerVoucher memory _buyerVoucher,
        bytes memory globalSign
    ) external nonReentrant erc20Allowed(_sellerVoucher.erc20Token) {
        // globalSignValidation

        require(
            !isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce],
            "ERC721Marketplace: Nonce already processed"
        );

        ERC721MarketplaceHelper.validateLazyMintAuction(
            _sellerVoucher,
            _buyerVoucher,
            globalSign,
            _signer
        );

        // Calculating brokerage and validation
        _brokerage memory brokerage_ = brokerage[_sellerVoucher.erc20Token];

        uint256 buyingBrokerage = (brokerage_.buyer *
            _sellerVoucher.startingPrice) / (100 * decimalPrecision);

        require(
            _sellerVoucher.startingPrice + buyingBrokerage <=
                _buyerVoucher.amount,
            "ERC721Marketplace: Amount must include Buying Brokerage"
        );

        buyingBrokerage =
            (brokerage_.buyer * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        uint256 sellingBrokerage = (brokerage_.seller * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        uint256 tokenId = ERC721MarketplaceHelper.handleLazyMintAuction(
            _sellerVoucher,
            _buyerVoucher,
            WETH,
            mintingCharge,
            broker,
            sellingBrokerage,
            buyingBrokerage
        );

        isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce] = true;

        emit LazyAuction(
            _sellerVoucher.erc721,
            tokenId,
            _sellerVoucher.to,
            _buyerVoucher.buyer,
            _sellerVoucher.erc20Token,
            _buyerVoucher.amount,
            block.timestamp
        );
    }

    function lazyMint(
        address collection,
        address to,
        uint96 _royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        bytes memory sign,
        address buyer
    ) external payable nonReentrant returns (uint256) {
        require(
            !isNonceProcessed[collection][nonce],
            "ERC721Marketplace: Nonce already processed"
        );

        ERC721MarketplaceHelper.validateLazyMint(
            collection,
            to,
            _royalty,
            _tokenURI,
            nonce,
            price,
            sign
        );

        // Calculating brokerage and validation
        _brokerage memory brokerage_ = brokerage[address(0)];

        uint256 buyingBrokerage = (brokerage_.buyer * price) /
            (100 * decimalPrecision);

        uint256 sellingBrokerage = (brokerage_.seller * price) /
            (100 * decimalPrecision);

        require(
            msg.value >= price + buyingBrokerage + mintingCharge,
            "ERC721Marketplace: Isufficient fund."
        );

        payable(to).transfer(price - sellingBrokerage);
        broker.transfer(msg.value - (price - sellingBrokerage));

        uint256 tokenId = IERC721Mintable(collection).delegatedMint(
            _tokenURI,
            _royalty,
            to,
            buyer
        );

        isNonceProcessed[collection][nonce] = true;

        emit LazyMinted(
            collection,
            tokenId,
            to,
            buyer,
            address(0),
            price,
            block.timestamp
        );

        return tokenId;
    }

    function acceptLazyOffer(
        lazySellerVoucher memory _sellerVoucher,
        buyerVoucher memory _buyerVoucher,
        uint256 _nonce,
        bytes calldata _sign
    ) external nonReentrant returns (uint256) {
        // Seller validation.
        require(
            !isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce],
            "ERC721Marketplace: Nonce already processed"
        );

        ERC721MarketplaceHelper.validateAcceptLazyOffer(
            _sellerVoucher,
            _buyerVoucher,
            _nonce,
            _sign,
            WETH
        );

        require(
            !isOfferNonceProcessed[_nonce],
            "ERC721Marketplace: Offer is already processed."
        );

        // Handling WETH
        {
            IERC20Upgradeable _erc20Token = IERC20Upgradeable(WETH);
            _brokerage memory brokerage_;

            require(
                _erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount + mintingCharge &&
                    _erc20Token.balanceOf(_buyerVoucher.buyer) >=
                    _buyerVoucher.amount + mintingCharge,
                "ERC721Marketplace: Isufficient allowance or balance in bidder's account."
            );

            brokerage_.seller =
                (brokerage[address(_erc20Token)].seller *
                    _buyerVoucher.amount) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[address(_erc20Token)].buyer * _buyerVoucher.amount) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _buyerVoucher.amount -
                brokerage_.seller -
                brokerage_.buyer;

            _erc20Token.transferFrom(
                _buyerVoucher.buyer,
                msg.sender,
                sellerFund
            );
            _erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                brokerage_.seller + brokerage_.buyer + mintingCharge
            );

            _buyerVoucher.amount -= brokerage_.buyer;
        }

        // Handling NFT

        uint256 tokenId = IERC721Mintable(_sellerVoucher.erc721).delegatedMint(
            _sellerVoucher.tokenURI,
            _sellerVoucher.royalty,
            _sellerVoucher.to,
            _buyerVoucher.buyer
        );

        isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce] = true;
        isOfferNonceProcessed[_nonce] = true;

        emit LazyOfferAccepted(
            _sellerVoucher.erc721,
            tokenId,
            _sellerVoucher.to,
            _buyerVoucher.buyer,
            _buyerVoucher.amount,
            block.timestamp,
            WETH
        );

        return tokenId;
    }

    function acceptOffer(
        uint256 _tokenId,
        address _erc721,
        uint256 _amount,
        uint256 _validTill,
        address _bidder,
        IERC20Upgradeable _erc20Token,
        uint256 _nonce,
        bytes calldata _sign
    ) external nonReentrant tokenOwnerOnly(_tokenId, _erc721) {
        require(
            !isOfferNonceProcessed[_nonce],
            "ERC721Marketplace: Offer is already processed."
        );

        _brokerage memory brokerage_;
        brokerage_.seller =
            (brokerage[address(_erc20Token)].seller * _amount) /
            (100 * decimalPrecision);

        // Calculate Brokerage
        brokerage_.buyer =
            (brokerage[address(_erc20Token)].buyer * _amount) /
            (100 * decimalPrecision);

        ERC721MarketplaceHelper.handleAcceptOffer(
            _tokenId,
            _erc721,
            _amount,
            _validTill,
            _bidder,
            _erc20Token,
            _nonce,
            _sign,
            brokerage_,
            broker
        );
        _amount -= brokerage_.buyer;
        // Sold event
        emit OfferAccepted(
            _erc721,
            _tokenId,
            msg.sender,
            _bidder,
            _amount,
            block.timestamp,
            address(_erc20Token)
        );

        isOfferNonceProcessed[_nonce] = true;
    }

    function cancelOffer(
        uint256 _tokenId,
        address _erc721,
        uint256 _amount,
        uint256 _validTill,
        address _seller,
        address _erc20Token,
        uint256 _nonce,
        bytes calldata _sign
    ) external {
        ERC721MarketplaceHelper.validateCancelOffer(
            _tokenId,
            _erc721,
            _amount,
            _validTill,
            _seller,
            _erc20Token,
            _nonce,
            _sign
        );

        require(
            !isOfferNonceProcessed[_nonce],
            "ERC721Marketplace: Offer is already processed."
        );
        isOfferNonceProcessed[_nonce] = true;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}