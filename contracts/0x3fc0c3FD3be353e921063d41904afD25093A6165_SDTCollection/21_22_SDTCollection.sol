// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SDTToken.sol";

contract SDTCollection is ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _listingIds;

    address public coinAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint public coinDecimal = 6;

    mapping(uint => TokenItem) public tokens;
    mapping(uint => ListingItem) public listings;

    struct TokenItem {
        uint tokenID;
        uint fullPrice;
        uint price;
        uint minAmount;
        uint maxAmount;
        uint objectTokenizedPer;
        address erc20Address;
        uint status; // 0 - created; 1 - on listing;
    }

    struct ListingItem {
        uint listingID;
        uint tokenID;
        uint incomeAmount;
        uint incomeToken;
        address erc20Address;
        uint erc20Mint;
        uint status; // 0 - created; 1 - finalized; 2 - canceled
    }

    event ListingCreated(uint id, uint tokenID);
    event ListingChanged(uint id, uint tokenID);
    event ListingCanceled(uint id, uint tokenID);
    event ListingFinalized(uint id, uint tokenID);
    event ListingInvested(uint id, uint tokenID);
    event InvestmentCreate(uint listingID, uint tokenID, address account, uint amount);
    event InvestmentPay(uint listingID, uint tokenID, address account, uint amount, uint payAmount);
    event Withdrawal(address account, uint amount);

    constructor() ERC721("SDT Collection", "SDTC") {}

    function mint(address _owner, string memory _tokenURI, uint _fullPrice, uint _price, uint _minAmount, uint _maxAmount, uint _objectTokenizedPer, address _erc20Address) public nonReentrant onlyOwner returns (uint256){
        _tokenIds.increment();

        uint256 tokenID = _tokenIds.current();
        _mint(_owner, tokenID);
        _setTokenURI(tokenID, _tokenURI);
        tokens[tokenID] = TokenItem(tokenID, _fullPrice, _price, _minAmount, _maxAmount, _objectTokenizedPer, _erc20Address, 0);

        return tokenID;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function getTokensLength() public view returns (uint) {
        return _tokenIds.current();
    }

    function getListingsLength() public view returns (uint) {
        return _listingIds.current();
    }

    function changePrice(uint _tokenID, uint _price, string memory _tokenURI) public nonReentrant onlyOwner {
        TokenItem memory currentToken = tokens[_tokenID];
        require(currentToken.tokenID > 0, "STDCollection: invalid listing");

        _setTokenURI(_tokenID, _tokenURI);
        tokens[_tokenID] = TokenItem(currentToken.tokenID, currentToken.fullPrice, _price, currentToken.minAmount, currentToken.maxAmount, currentToken.objectTokenizedPer, currentToken.erc20Address, currentToken.status);
    }


    function createListing(uint _tokenID) public nonReentrant onlyOwner {
        TokenItem memory currentToken = tokens[_tokenID];
        require(currentToken.tokenID > 0, "STDCollection: invalid listing");

        _listingIds.increment();
        uint256 listingID = _listingIds.current();

        listings[listingID] = ListingItem(listingID, _tokenID, 0, 0, currentToken.erc20Address, 0, 0);
        tokens[_tokenID] = TokenItem(currentToken.tokenID, currentToken.fullPrice, currentToken.price, currentToken.minAmount, currentToken.maxAmount, currentToken.objectTokenizedPer, currentToken.erc20Address, 1);

        emit ListingCreated(listingID, _tokenID);
    }

    function finalizeListing(uint _listingID, uint _incomeAmount) public nonReentrant onlyOwner {
        ListingItem memory currentListing = listings[_listingID];
        require(currentListing.tokenID > 0, "STDCollection: invalid listing");

        TokenItem memory currentToken = tokens[currentListing.tokenID];
        require(currentToken.tokenID > 0, "STDCollection: invalid token");

        uint investToken = ((_incomeAmount * currentToken.objectTokenizedPer) / 100) / currentToken.maxAmount;
        listings[_listingID] = ListingItem(currentListing.listingID, currentListing.tokenID, investToken, _incomeAmount, currentListing.erc20Address, currentListing.erc20Mint, 1);
        tokens[currentListing.tokenID] = TokenItem(currentToken.tokenID, currentToken.fullPrice, currentToken.price, currentToken.minAmount, currentToken.maxAmount, currentToken.objectTokenizedPer, currentToken.erc20Address, 0);

        emit ListingFinalized(_listingID, currentListing.tokenID);
    }

    function cancelListing(uint _listingID) public nonReentrant onlyOwner {
        ListingItem memory currentListing = listings[_listingID];
        require(currentListing.tokenID > 0, "STDCollection: invalid listing");

        TokenItem memory currentToken = tokens[currentListing.tokenID];
        require(currentToken.tokenID > 0, "STDCollection: invalid token");

        listings[_listingID] = ListingItem(currentListing.listingID, currentListing.tokenID, 0, 0, currentListing.erc20Address, currentListing.erc20Mint, 2);
        tokens[currentListing.tokenID] = TokenItem(currentToken.tokenID, currentToken.fullPrice, currentToken.price, currentToken.minAmount, currentToken.maxAmount, currentToken.objectTokenizedPer, currentToken.erc20Address, 0);

        emit ListingCanceled(_listingID, currentListing.tokenID);
    }

    function createInvest(uint _listingID, uint _amount) public payable nonReentrant {
        ListingItem memory currentListing = listings[_listingID];
        require(currentListing.tokenID > 0, "STDCollection: invalid listing");
        require(currentListing.status == 0, "STDCollection: invalid status");

        IERC20(coinAddress).safeTransferFrom(msg.sender, address(this), _amount * 10 ** coinDecimal);

        TokenItem memory currentToken = tokens[currentListing.tokenID];
        require(currentToken.tokenID > 0, "STDCollection: invalid token");

        uint erc20Mint = _amount / currentToken.price;
        require(currentListing.erc20Mint + erc20Mint <= currentToken.maxAmount, "STDCollection: max tokenized");
        require(SDTToken(currentListing.erc20Address).mint(msg.sender, erc20Mint * 10 ** 18), "STDCollection: invalid mint");

        listings[_listingID] = ListingItem(currentListing.listingID, currentListing.tokenID, 0, 0, currentListing.erc20Address, currentListing.erc20Mint + erc20Mint, currentListing.status);

        emit InvestmentCreate(currentListing.listingID, currentListing.tokenID, msg.sender, _amount);
    }

    function payInvest(uint _listingID, uint _amount) public payable nonReentrant {
        ListingItem memory currentListing = listings[_listingID];
        require(currentListing.tokenID > 0, "STDCollection: invalid listing");
        require(currentListing.status == 1, "STDCollection: invalid status");

        uint payAmount = currentListing.incomeAmount * _amount;

        SDTToken(currentListing.erc20Address).burn(msg.sender, _amount * 10 ** 18);
        IERC20(coinAddress).safeTransfer(msg.sender, payAmount * 10 ** coinDecimal);

        emit InvestmentPay(currentListing.listingID, currentListing.tokenID, msg.sender, _amount, payAmount);
    }

    function withdrawal(uint _amount) public payable nonReentrant onlyOwner {
        IERC20(coinAddress).safeTransfer(msg.sender, _amount * 10 ** coinDecimal);

        emit Withdrawal(msg.sender, _amount);
    }

    function changeCoin(address _address, uint _decimal) public nonReentrant onlyOwner {
        coinAddress = _address;
        coinDecimal = _decimal;
    }
}