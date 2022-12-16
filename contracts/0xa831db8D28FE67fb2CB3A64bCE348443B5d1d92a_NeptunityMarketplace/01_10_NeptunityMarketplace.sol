// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/INeptunity.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ███    ██ ███████ ██████  ████████ ██    ██ ███    ██ ██ ████████ ██    ██
// ████   ██ ██      ██   ██    ██    ██    ██ ████   ██ ██    ██     ██  ██
// ██ ██  ██ █████   ██████     ██    ██    ██ ██ ██  ██ ██    ██      ████
// ██  ██ ██ ██      ██         ██    ██    ██ ██  ██ ██ ██    ██       ██
// ██   ████ ███████ ██         ██     ██████  ██   ████ ██    ██       ██

contract NeptunityMarketplace is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter; // counters for marketplace

    Counters.Counter private ordersCounter; // orders counter
    Counters.Counter private offersCounter; // offers counter
    // solhint-disable-next-line
    INeptunity private NeptunityERC721;

    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; //keccak256("MINTER_ROLE");
    bytes32 private constant MINTER_ROLE_MANAGER =
        0x3d56c6b2572263081c65bd5409e23369bba6fe5164eaf66eb49349dcd212d6d3; //keccak256("MINTER_ROLE_MANAGER");

    mapping(uint256 => Innovice) public orders; // mapping order id to invoice struct.
    mapping(uint256 => Innovice) private offers; // mapping offer id to invoice struct.

    /********************************/
    /*********** STRUCTS ************/
    /********************************/
    struct Innovice {
        uint256 tokenId; // is token id of nft
        uint256 price; // is reserve price or the highest bid for the auction
        address from; // is the creator of the the of order
    }
    struct TradeInnovice {
        uint256 tokenId;
        uint256 orderId;
        uint256 price;
        address from; // seller of the nft
        address to; // buyer of the nft
    }

    /********************************/
    /************ EVENTS ************/
    /********************************/

    /**
     * @notice Emitted when an NFT is listed for sale on fix price
     * @param from The address of the seller
     * @param orderId The id of the order that was created
     * @param tokenId The id of the NFT
     * @param price The sale price onf NFT
     */
    event Order(
        address indexed from,
        uint256 indexed orderId,
        uint256 indexed tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an listing is cancelled for sale on fix price
     * @param from The address of the seller
     * @param orderId The id of the order that was created
     * @param tokenId The id of the NFT
     */
    event OrderRemoved(
        address indexed from,
        uint256 indexed orderId,
        uint256 indexed tokenId
    );

    /**
     * @notice Emitted when an offer is made for an NFT
     * @param from The address of the offer maker
     * @param offerId The id of the offer that was created
     * @param tokenId The id of the NFT
     */
    event Offered(
        address indexed from,
        uint256 indexed offerId,
        uint256 indexed tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an listing is cancelled for sale on fix price
     * @param from The address of the seller
     * @param offerId The id of the order that was created
     * @param tokenId The id of the NFT
     */
    event OfferRemoved(
        address indexed from,
        uint256 indexed offerId,
        uint256 indexed tokenId
    );

    /**
     * @notice Emitted when an order is filled or offer is accpeted for NFT
       @param  tokenId is the id of NFT which has been traded       
       @param  orderId is the id of order if it is an order which has been filled. otherwise it will be 0
       @param  price is amount in wei for which the NFT has been traded
       @param  from is seller of the nft
       @param  to is buyer of the nft
     -
     */
    event Traded(
        address indexed from,
        address to,
        uint256 indexed tokenId,
        uint256 orderId,
        uint256 price,
        uint256 royaltiesFee,
        uint256 marketFee
    );

    /********************************/
    /*********** MODIFERS ***********/
    /********************************/

    modifier isOrderOwner(uint256 _orderId) {
        // solhint-disable-next-line
        require(orders[_orderId].from == msg.sender);
        _;
    }

    modifier isOfferOwner(uint256 _offerId) {
        // solhint-disable-next-line
        require(offers[_offerId].from == msg.sender);
        _;
    }

    /********************************/
    /************ METHODS ***********/
    /********************************/

    /**
     * @dev mints a token
     * @param _tokenURI is URI of the NFT's metadata
     * @param _artistFee is bps value for percentage for NFT's secondary sale
     */
    function mint(string memory _tokenURI, uint24 _artistFee)
        external
        onlyRole(MINTER_ROLE)
    {
        NeptunityERC721.mint(_tokenURI, msg.sender, _artistFee);
    }

    function createOrder(uint256 _tokenId, uint256 _price) external {
        // solhint-disable-next-line
        require(_price > 0);

        NeptunityERC721.transferFrom(msg.sender, address(this), _tokenId); // transfer token to contract

        ordersCounter.increment();

        uint256 _orderId = ordersCounter.current();

        orders[_orderId] = Innovice(_tokenId, _price, msg.sender);

        emit Order(msg.sender, _orderId, _tokenId, _price);
    }

    function fillOrder(uint256 _orderId) external payable {
        Innovice memory _order = orders[_orderId];

        // solhint-disable-next-line
        require(msg.value >= _order.price);

        TradeInnovice memory _tradeInnovice = TradeInnovice(
            _order.tokenId,
            _orderId,
            _order.price,
            payable(_order.from),
            msg.sender
        );

        _trade(_tradeInnovice);
    }

    function modifyOrderPrice(uint256 _orderId, uint256 _updatedPrice)
        external
        isOrderOwner(_orderId)
    {
        // solhint-disable-next-line
        require(_updatedPrice > 0);
        Innovice storage _order = orders[_orderId];
        _order.price = _updatedPrice;

        emit Order(msg.sender, _orderId, _order.tokenId, _updatedPrice);
    }

    function removeOrder(uint256 _orderId) external isOrderOwner(_orderId) {
        Innovice memory _order = orders[_orderId];

        NeptunityERC721.transferFrom(
            address(this),
            _order.from,
            _order.tokenId
        ); // transfer token to owner

        delete orders[_orderId]; // mark order as cancelled

        emit OrderRemoved(_order.from, _orderId, _order.tokenId);
    }

    function createOffer(uint256 _tokenId) external payable {
        // solhint-disable-next-line
        require(msg.value > 0); // offer should be more than 0 wei

        offersCounter.increment(); // update counter
        uint256 _offerId = offersCounter.current();

        offers[_offerId] = Innovice(_tokenId, msg.value, msg.sender);

        emit Offered(msg.sender, _offerId, _tokenId, msg.value);
    }

    function fillOffer(uint256 _offerId, uint256 _orderId) external {
        Innovice memory _offer = offers[_offerId];

        // solhint-disable-next-line
        if (_orderId != 0) require(orders[_orderId].from == msg.sender);

        delete offers[_offerId]; // mark offer as complete

        TradeInnovice memory _tradeInnovice = TradeInnovice(
            _offer.tokenId,
            _orderId,
            _offer.price,
            payable(msg.sender),
            _offer.from
        );

        _trade(_tradeInnovice);
    }

    function modifyOfferPrice(uint256 _offerId)
        external
        payable
        isOfferOwner(_offerId)
        nonReentrant
    {
        // solhint-disable-next-line
        require(msg.value > 0);
        Innovice storage _offer = offers[_offerId];

        uint256 _oldOffer = _offer.price;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: _oldOffer}(""); // pay old offer amount
        // solhint-disable-next-line
        require(success);
        _offer.price = msg.value;

        emit Offered(msg.sender, _offerId, _offer.tokenId, msg.value);
    }

    function removeOffer(uint256 _offerId)
        external
        isOfferOwner(_offerId)
        nonReentrant
    {
        Innovice memory _offer = offers[_offerId];

        delete offers[_offerId]; // mark order as cancelled

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(_offer.from).call{value: _offer.price}(""); // transfer the offer amount back to bidder
        // solhint-disable-next-line
        require(success);

        emit OfferRemoved(_offer.from, _offerId, _offer.tokenId);
    }

    /**
     * @dev to exchange the  NFT and amount
     */
    function _trade(TradeInnovice memory _tradeInnovice) private {
        uint256 sellerAmount = _tradeInnovice.price;
        uint256 marketplaceAmount;
        uint256 royaltiesFee;
        bool success;

        if (_tradeInnovice.orderId != 0) {
            delete orders[_tradeInnovice.orderId]; // mark order as complete

            NeptunityERC721.transferFrom(
                address(this),
                _tradeInnovice.to,
                _tradeInnovice.tokenId
            );
        } else {
            NeptunityERC721.transferFrom(
                _tradeInnovice.from,
                _tradeInnovice.to,
                _tradeInnovice.tokenId
            );
        }

        // extract data from neptunitySate
        (
            address feeAccount,
            bool isSecondarySale,
            uint24 artistFee,
            uint24 marketplaceFee,
            address artist
        ) = NeptunityERC721.getStateInfo(_tradeInnovice.tokenId);

        marketplaceAmount = (sellerAmount * marketplaceFee) / 10000;
        sellerAmount -= marketplaceAmount; // subtracting primary or secondary fee amount
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = feeAccount.call{value: marketplaceAmount}(""); // pay marketplaceFee
        // solhint-disable-next-line
        require(success);

        if (!isSecondarySale) {
            NeptunityERC721.setSecondarySale(_tradeInnovice.tokenId);
        } else {
            royaltiesFee = (sellerAmount * artistFee) / 10000; // Fee paid by the user that fills the order, a.k.a. msg.sender.
            sellerAmount -= royaltiesFee;

            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = payable(artist).call{value: royaltiesFee}(""); // transfer secondary sale fees to fee artist
            // solhint-disable-next-line reason-string
            require(success);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = _tradeInnovice.from.call{value: sellerAmount}(""); // pay the seller fee (price - marketplaceFee )
        // solhint-disable-next-line
        require(success);

        emit Traded(
            _tradeInnovice.from,
            _tradeInnovice.to,
            _tradeInnovice.tokenId,
            _tradeInnovice.orderId,
            _tradeInnovice.price,
            royaltiesFee,
            marketplaceAmount
        );
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
     */
    constructor(address neptunityERC721) {
        require(neptunityERC721 != address(0), "Invalid address");
        // default values
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // the deployer must have admin role. It is not possible if this role is not granted.
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE_MANAGER); // minter role manager can only assign minter role

        NeptunityERC721 = INeptunity(neptunityERC721);
    }
}