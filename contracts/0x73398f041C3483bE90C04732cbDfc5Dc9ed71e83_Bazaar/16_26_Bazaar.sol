// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../utils/HasAuthorization.sol";
import "../token/ERC2981/IERC2981.sol";
import "../token/ERC1155/extensions/ERC1155PreMintedCollection.sol";
import "../utils/Monetary.sol";
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
    using Monetary for Monetary.Crypto;

    event Created(uint id, address seller, Asset asset, Monetary.Crypto price);
    event OfferMade(uint id, address buyer, Asset asset, Monetary.Crypto price);
    event OfferRetracted(uint id, address buyer, Asset asset, Monetary.Crypto price);
    event Canceled(uint id, Asset asset);

    struct Sale {
        Asset asset;
//        address collection;
//        uint tokenId;
//        uint amount; // ceiling amount for sale. if tokenId == 0 & amount == 0, it means ALL owned by seller (ALL_OUT_SALE)
        address seller;
        Monetary.Crypto price; // per unit
    }
    struct Offer {
        Asset asset;
        Monetary.Crypto price; // per unit
    }

    uint constant ALL_OUT_SALE = 0;
    uint public currentSaleId;
    mapping(uint => Sale) public sales; // sale-id => Sale
    mapping(address => mapping(uint => mapping(uint => Offer))) public offers; // buyer => sale-id => tokenId => Offer

    modifier exists(uint id) { if (!isExistingSale(id)) revert NoSuchMarketplace(id); _; }

    constructor(address[] memory owners, address recipient, uint24 basispoints) HasFees(owners, recipient, basispoints) {}

    function _createSale(Asset memory asset, Monetary.Crypto memory price) private returns (uint) {
        uint id = ++currentSaleId;
        sales[id] = Sale(asset, msg.sender, price);
        emit Created(id, msg.sender, asset, price);
        return id;
    }

    function createSale(Asset memory asset, Monetary.Crypto memory price) external returns (uint) {
        validate(asset);
        return _createSale(asset, price);
    }

    function createAllOutSale(address collection, Monetary.Crypto memory price) external returns (uint) {
        validateAllOutSale(collection);
        return _createSale(Asset(collection, ALL_OUT_SALE, ALL_OUT_SALE), price);
    }

    function validateAllOutSale(address collection) private view {
        IERC165(collection).supportsInterface(type(IERC721).interfaceId) ?
            require(IERC721(collection).isApprovedForAll(msg.sender, address(this)), "ERC721: contract not approved for transfer") :
            IERC165(collection).supportsInterface(type(IERC1155).interfaceId) ?
                require(IERC1155(collection).isApprovedForAll(msg.sender, address(this)), "ERC1155: contract not approved for transfer") :
                revert("only ERC721 & ERC1155 collections are supported");
    }

    function isExistingSale(uint saleId) public view returns (bool) {
        return sales[saleId].seller != address(0);
    }

    function isAllOutSale(uint saleId) public view returns (bool) {
        return sales[saleId].asset.tokenId == ALL_OUT_SALE && sales[saleId].asset.amount == ALL_OUT_SALE;
    }

    function makeOffer(uint saleId, uint tokenId, uint amount, Monetary.Crypto memory price) external payable nonReentrant {
        _makeOffer(saleId, tokenId, amount, price, Monetary.Native(msg.value));
    }

    function makeOfferWithERC20(uint saleId, uint tokenId, uint amount, Monetary.Crypto memory price, Monetary.Crypto memory deposit) external nonReentrant {
        deposit.transferFromSender();
        _makeOffer(saleId, tokenId, amount, price, deposit);
    }

    function _makeOffer(uint saleId, uint tokenId, uint amount, Monetary.Crypto memory price, Monetary.Crypto memory deposit) private exists(saleId) {
        address buyer = msg.sender;
        Sale storage sale = sales[saleId];
        if (!isAllOutSale(saleId)) {
            require(sale.asset.tokenId == tokenId, "token id offered for is not for sale");
            require(sale.asset.amount >= amount, "desired amount exceeds amount sold limit");
        }
        Monetary.Crypto memory available = retractPrevious(buyer, saleId, tokenId).plus(deposit);
        Monetary.Crypto memory cost = price.multipliedBy(amount);
        if (cost.isGreaterThan(available)) revert InsufficientFunds(cost, available);
        if (available.isGreaterThan(cost)) available.minus(cost).transferTo(msg.sender); // refund overflow
        offers[buyer][saleId][tokenId] = Offer(Asset(sale.asset.collection, tokenId, amount), price);
        emit OfferMade(saleId, buyer, Asset(sale.asset.collection, tokenId, amount), price);
        if (!sale.price.isGreaterThan(price)) acceptOffer(saleId, sale, offers[buyer][saleId][tokenId], buyer, tokenId);
    }

    function retractOffer(uint saleId, uint tokenId) external {
        Monetary.Crypto memory deposit = retractPrevious(msg.sender, saleId, tokenId);
        require(!deposit.isZero(), "no such offer");
        deposit.transferTo(msg.sender);
    }

    function retractPrevious(address buyer, uint saleId, uint tokenId) private returns (Monetary.Crypto memory) {
        Offer storage offer = offers[buyer][saleId][tokenId];
        if (offer.asset.amount == 0) return Monetary.Zero(sales[saleId].price.currency); // offer does not exist
        Monetary.Crypto memory deposit = offer.price.multipliedBy(offer.asset.amount);
        emit OfferRetracted(saleId, buyer, offer.asset, offer.price);
        delete offers[buyer][saleId][tokenId];
        return deposit;
    }

    function acceptOffer(uint saleId, address buyer, uint tokenId, Monetary.Crypto memory price) external nonReentrant exists(saleId) only(sales[saleId].seller) {
        Sale storage sale = sales[saleId];
        Offer storage offer = offers[buyer][saleId][tokenId];
        require(offer.price.isEqualTo(price), "offer has changed");
        acceptOffer(saleId, sale, offer, buyer, tokenId);
    }

    function acceptOffer(uint saleId, Sale storage sale, Offer storage offer, address buyer, uint tokenId) private {
        uint balance = balanceOf(sale.asset.collection, sale.seller, tokenId);
        uint available = (isAllOutSale(saleId) || sale.asset.amount >= balance) ? balance : sale.asset.amount;
        if (available < offer.asset.amount) revert InsufficientTokens(saleId, offer.asset.amount, available);
        exchange(saleId, Asset(sale.asset.collection, tokenId, offer.asset.amount), offer.price, sale.seller, buyer);
        if (!isAllOutSale(saleId)) {
            sale.asset.amount -= offer.asset.amount;
            if (sale.asset.amount == 0) delete sales[saleId];
        }
        delete offers[buyer][saleId][tokenId];
    }

    function exchange(uint saleId, Asset memory asset, Monetary.Crypto memory price, address from, address to) internal virtual override {
        deliverSoldToken(saleId, asset, price, from, to);
        deliverPayment(saleId, asset, price.multipliedBy(asset.amount), from);
    }

    // the seller wishes to cancel sale of remaining tokens in collection
    function cancel(uint saleId) external exists(saleId) only(sales[saleId].seller) {
        emit Canceled(saleId, sales[saleId].asset);
        delete sales[saleId];
    }
}