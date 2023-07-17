// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ERC721Tradable is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter _tokenIdCounter;
    string public _tokenUri = "https://bearhood.club/metadata/";

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _tokenIdCounter.increment();
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}

contract BearHood is ERC721Tradable {
    using Counters for Counters.Counter;

    uint256 MaxSupply = 10000;

    address blindboxAddress;
    bool canOpen = false;
    bool openMarket = false;

    modifier allowOpenBox() {
        require(canOpen, "Box cannot be opened yet!");
        _;
    }

    modifier marketOpened() {
        require(openMarket, "Market closed");
        _;
    }

    constructor()
        ERC721Tradable("BearHood", unicode"(●￣(ｴ)￣●)")
    {}

    function openBox(address to) public allowOpenBox returns(uint256) {
        require(msg.sender == blindboxAddress, "Not authorized");
        require(_tokenIdCounter.current() <= MaxSupply);
        uint256 mintedId =  _tokenIdCounter.current();

        _safeMint(to, mintedId);
        _tokenIdCounter.increment();
        return mintedId;
    }

    function setBoxAddress(address newAddress) public onlyOwner { 
        blindboxAddress = newAddress;
    }

    function adjustBaseUri(string memory newUri) public onlyOwner {
        _tokenUri = newUri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://bearhood.eth.link/contact-meta";
    }

    function toggle(uint256 _switcher) public onlyOwner {
        if(_switcher == 0) {
            canOpen = !canOpen;
        } else if(_switcher == 1) {
            openMarket = !openMarket;
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) return new uint256[](0);
		else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

    //MarketPlace
    event BearOffered(uint256 indexed bearId, uint256 minValue, address indexed toAddress);
    event BearBidEntered(uint256 indexed bearId, uint256 value, address indexed fromAddress);
    event BearBidWithdrawn(uint256 indexed bearId, uint256 value, address indexed fromAddress);
    event BearBought(uint256 indexed bearId, uint256 value, address indexed fromAddress, address indexed toAddress);
    event BearNoLongerForSale(uint256 indexed bearId);

    uint256 royalFee = 950;

    struct Offer {
        bool isForSale;
        uint256 bearId;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 bearId;
        address bidder;
        uint256 value;
    }

    mapping (uint256 => Offer) public bearOffers;
    mapping (uint256 => Bid) public bearBids;

    function bearListForSale(uint256 bearId, uint256 price) public marketOpened {
        require(bearId <= 10000, "Index out of range!");
        require(ownerOf(bearId) == msg.sender, "You are not the Owner!");
        bearOffers[bearId] = Offer(true, bearId, msg.sender, price, address(0));
        emit BearOffered(bearId, price, address(0));
    }

    function bearUnlist(uint256 bearId) public marketOpened {
        require(bearId <= 10000, "Index out of range!");
        require(ownerOf(bearId) == msg.sender, "You are not the Owner!");
        bearOffers[bearId] = Offer(false, bearId, msg.sender, 0, address(0));
        emit BearNoLongerForSale(bearId);
    }

    function offerBearToAddress(uint256 bearId, uint256 price, address toAddress) public marketOpened {
        require(bearId <= 10000, "Index out of range!");
        require(ownerOf(bearId) == msg.sender, "You are not the Owner!");
        bearOffers[bearId] = Offer(true, bearId, msg.sender, price, toAddress);
        emit BearOffered(bearId, price, toAddress);
    }

    function buyBear(uint256 bearId) public payable marketOpened {
        Offer storage offer = bearOffers[bearId];
        require(bearId <= 10000, "Index out of range!");
        require(offer.isForSale, "This Bear is not for sale!");
        require(offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender, "You cannot buy this bear!");
        require(msg.value >= offer.minValue, "Insuffcient Fund");
        require(ownerOf(bearId) != msg.sender, "Owner cannot buy!");

        address payable seller = payable(offer.seller);
        _safeTransfer(seller, msg.sender, bearId, "");

        seller.transfer(offer.minValue*royalFee/1000);
        bearOffers[bearId] = Offer(false, bearId, msg.sender, 0, address(0));
        emit BearBought(bearId, msg.value, seller, msg.sender);

        Bid storage bid = bearBids[bearId];
        if (bid.bidder == msg.sender) {
            payable(msg.sender).transfer(bid.value);
            bearBids[bearId] = Bid(false, bearId, address(0), 0);
        }
    }

    function bidBear(uint256 bearId, uint256 bidPrice) public payable marketOpened {
        require(bearId <= 10000, "Index out of range!");
        require(ownerOf(bearId) != msg.sender, "Owner cannot bid!");
        require(bidPrice > 0);
        Bid storage existing = bearBids[bearId];
        require(msg.value >= bidPrice && msg.value >= existing.value, "Insuffcient Bid");
        if (existing.value > 0) {
            payable(existing.bidder).transfer(existing.value);
        }
        bearBids[bearId] = Bid(true, bearId, msg.sender, msg.value);
        emit BearBidEntered(bearId, bidPrice, msg.sender);
    }

    function acceptBid(uint256 bearId) public marketOpened {
        require(bearId <= 10000, "Index out of range!");
        require(ownerOf(bearId) == msg.sender, "You are not the Owner!");
        address payable seller = payable(msg.sender);
        Bid storage bid = bearBids[bearId];
        require(bid.value > 0);
        _safeTransfer(msg.sender, bid.bidder, bearId, "");

        bearOffers[bearId] = Offer(false, bearId, bid.bidder, 0, address(0));
        uint256 amount = bid.value;
        seller.transfer(amount*royalFee/1000);
        bearBids[bearId] = Bid(false, bearId, address(0), 0);
        emit BearBought(bearId, bid.value, seller, bid.bidder);
    }

    function withdrawBid(uint256 bearId) public marketOpened {
        require(bearId <= 10000, "Index out of range!");
        Bid storage bid = bearBids[bearId];
        require(bid.bidder == msg.sender, "You are not the bidder!");
        
        uint256 amount = bid.value;
        bearBids[bearId] = Bid(false, bearId, address(0), 0);
        emit BearBidWithdrawn(bearId, bid.value, msg.sender);
        payable(msg.sender).transfer(amount);
    }

    function setRoyalFee(uint256 fee) public onlyOwner {
        royalFee = fee;
    }

    function ifBearOffered(uint256 bearId) public view returns(bool){
        Offer memory offer = bearOffers[bearId];
        return offer.isForSale;
    }

    function ifBearBidded(uint256 bearId) public view returns(bool){
        Bid memory bid = bearBids[bearId];
        return bid.hasBid;
    }

    function getBearOffer(uint256 bearId) public view returns(
        bool isForSale,
        address owner,
        uint256 price,
        address onlySellTo
    ) {
        Offer memory offer = bearOffers[bearId];
        isForSale = offer.isForSale;
        owner = offer.seller;
        price = offer.minValue;
        onlySellTo = offer.onlySellTo;
    }

    function getBearBid(uint256 bearId) public view returns(
        bool hasBid,
        address owner,
        address bidder,
        uint256 bidPrice
    ) {
        Bid memory bid = bearBids[bearId];
        hasBid = bid.hasBid;
        owner = ownerOf(bearId);
        bidder = bid.bidder;
        bidPrice = bid.value;
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}