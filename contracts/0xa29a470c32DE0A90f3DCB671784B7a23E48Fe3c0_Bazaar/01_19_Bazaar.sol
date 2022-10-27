// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../utils/HasAuthorization.sol";
import "../token/ERC2981/IERC2981.sol";
import "../token/ERC1155/extensions/ERC1155PreMintedCollection.sol";
import "./Marketplace.sol";


/**
 * a Bazaar is an interactive marketplace where:
 * seller lists, potential buyer makes an offer, which the seller in turn either accepts or ignores
 *
 * this implementation varies in the following manner:
 *  1. the sale starts immediately and is not time-bounded
 *  2. a (potential) buyer can buy any amount of the tokenId, as long as the seller own such amount
 *  3. an offer involves an escrow and is not time-bounded
 *  4. an offer is accepted automatically if it is at the asking price or above
 *  5. the buyer can retract the offer at any time
 *  6. the buyer can update the offer at any time
 *  7. the seller can cancel the sale at any time
 *
 * @notice a Sale is conducted without an escrow
 */
contract Bazaar is Marketplace, HasAuthorization, ReentrancyGuard {
    using Address for address payable;

    event Created(uint id, address seller, address collection, uint tokenId, uint amount, uint price);
    event OfferMade(uint id, address collection, address buyer, uint tokenId, uint amount, uint price);
    event OfferRetracted(uint id, address collection, address buyer, uint tokenId, uint amount, uint price);
    event Canceled(uint id, address collection, uint tokenId);

    struct Sale {
        address collection;
        uint tokenId;   // 0 means ALL tokens
        uint amount;    // ceiling amount for sale. if tokenId == 0 then amount == ALL, which means ALL owned by seller
        address seller;
        uint price;     // per unit
    }
    struct Offer {
        uint amount;
        uint price; // per unit
    }

    uint constant ALL = 0;
    uint public currentSaleId;
    mapping(uint => Sale) public sales; // id => Sale
    mapping(address => mapping(uint => mapping(uint => Offer))) public offers; // buyer => sale-id => tokenId => Offer

    modifier exists(uint id) { if (sales[id].seller == address(0)) revert NoSuchMarketplace(id); _; }

    constructor(address[] memory owners, address recipient, uint24 basispoints) HasFees(owners, recipient, basispoints) {}

    function _createSale(address collection, uint tokenId, uint amount, uint price) private returns (uint) {
        require(IERC1155(collection).isApprovedForAll(msg.sender, address(this)), "contract not approved for transfer");
        uint id = ++currentSaleId;
        sales[id] = Sale(collection, tokenId, amount, msg.sender, price);
        emit Created(id, msg.sender, collection, tokenId, amount, price);
        return id;
    }

    function createSale(address collection, uint tokenId, uint amount, uint price) external returns (uint) {
        require(amount != 0, "sale amount must be positive");
        return _createSale(collection, tokenId, amount, price);
    }

    function createAllOutSale(address collection, uint price) external returns (uint) {
        return _createSale(collection, ALL, ALL, price);
    }

    function isAllOutSale(uint saleId) public view returns (bool) { return sales[saleId].tokenId == ALL; }

    function makeOffer(uint saleId, uint tokenId, uint amount, uint price) external payable nonReentrant exists(saleId) {
        address buyer = msg.sender;
        Sale storage sale = sales[saleId];
        if (!isAllOutSale(saleId)) {
            require(sale.tokenId == tokenId, "token id offered for is not for sale");
            require(sale.amount >= amount, "desired amount exceeds amount sold limit");
        }
        uint totalValue = retractPrevious(buyer, saleId, tokenId) + msg.value;
        if (totalValue < amount * price) revert InsufficientFunds(amount * price, totalValue);
        uint toBeReturned = totalValue - amount * price;
        offers[buyer][saleId][tokenId] = Offer(amount, price);
        emit OfferMade(saleId, sale.collection, buyer, tokenId, amount, price);
        if (price >= sale.price) acceptOffer(saleId, sale, offers[buyer][saleId][tokenId], buyer, tokenId);
        if (toBeReturned > 0) payable(msg.sender).sendValue(toBeReturned);
    }

    function retractOffer(uint saleId, uint tokenId) external {
        uint toBeReturned = retractPrevious(msg.sender, saleId, tokenId);
        require(toBeReturned != 0, "no such offer");
        payable(msg.sender).sendValue(toBeReturned);
    }

    function retractPrevious(address buyer, uint saleId, uint tokenId) private returns (uint) {
        Offer storage offer = offers[buyer][saleId][tokenId];
        if (offer.amount == 0) return 0; // offer does not exist
        uint amount = offer.amount * offer.price;
        emit OfferRetracted(saleId, sales[saleId].collection, buyer, tokenId, offer.amount, offer.price);
        delete offers[buyer][saleId][tokenId];
        return amount;
    }

    function acceptOffer(uint saleId, address buyer, uint tokenId, uint price) external nonReentrant exists(saleId) only(sales[saleId].seller) {
        Sale storage sale = sales[saleId];
        Offer storage offer = offers[buyer][saleId][tokenId];
        require(offer.price == price, "offer has changed");
        acceptOffer(saleId, sale, offer, buyer, tokenId);
    }

    function acceptOffer(uint saleId, Sale storage sale, Offer storage offer, address buyer, uint tokenId) private {
        uint balance = IERC1155(sale.collection).balanceOf(sale.seller, tokenId);
        uint available = (isAllOutSale(saleId) || sale.amount >= balance) ? balance : sale.amount;
        if (available < offer.amount) revert InsufficientTokens(saleId, offer.amount, available);
        exchange(saleId, sale.collection, tokenId, offer.amount, offer.price, sale.seller, buyer);
        if (!isAllOutSale(saleId)) {
            sale.amount -= offer.amount;
            if (sale.amount == 0) delete sales[saleId];
        }
        delete offers[buyer][saleId][tokenId];
    }

    function exchange(uint saleId, address collection, uint tokenId, uint amount, uint price, address from, address to) internal virtual override {
        deliverSoldToken(saleId, collection, tokenId, amount, price, from, to);
        deliverPayment(saleId, collection, tokenId, amount, amount * price, from);
    }

    // the seller wishes to cancel sale of remaining tokens in collection
    function cancel(uint saleId) external exists(saleId) only(sales[saleId].seller) {
        emit Canceled(saleId, sales[saleId].collection, sales[saleId].tokenId);
        delete sales[saleId];
    }
}