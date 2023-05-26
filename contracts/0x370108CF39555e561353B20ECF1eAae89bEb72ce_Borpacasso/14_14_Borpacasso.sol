// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Borpacasso is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;

    mapping(address => bool) public whitelist;
    uint32 private constant maxTokensPerTransaction = 25;
    uint256 private tokenPrice = 75000000000000000; //0.075 ETH
    uint256 private constant nftsNumber = 2250;
    uint256 private constant nftsPublicNumber = 2225;
    address private constant borpFanOne = 0xb0e7d87fCB3d146d55EB694f9851833f18a7dB11;
    address private constant borpFanTwo = 0xCd2732220292022cC8Ab82173D213f4F51F99f76;
    bool public whitelistSaleActive = false;
    bool public mainSaleActive = false;
    bool public uriUnlocked = true;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Borpacasso", "BORP1") {
        _tokenIdCounter.increment();
    }
    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        require(uriUnlocked, "Not happening.");
        _baseURIPrefix = baseURIPrefix;
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
        function lockURI() public onlyOwner {
        uriUnlocked = false;
        }
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    function howManyBorp() public view returns(uint256 a){
       return Counters.current(_tokenIdCounter);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint cut = balance.div(2);
        payable(borpFanOne).transfer(cut);
        payable(borpFanTwo).transfer(cut);
    }
   function mintGiveawayBorps(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Wait for the sale to end first, stoopid");
        _safeMint(to, tokenId);
    }
    function addToWhitelist(address[] memory _address)public onlyOwner {
       for(uint i = 0; i < _address.length; i++) {
        whitelist[_address[i]]=true;
       }
    }
     function removeFromWhitelist(address[] memory _address)public onlyOwner {
       for(uint i = 0; i < _address.length; i++) {
        whitelist[_address[i]]=false;
       }
    }
    function flipWhitelistSale() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }
    function flipMainSale() public onlyOwner {
        mainSaleActive = !mainSaleActive;
    }
     function buyWhitelistBorp() public payable {
        require(whitelistSaleActive, "Maybe later");
        require(_tokenIdCounter.current().add(1) <= nftsPublicNumber, "Sry I dont have enough left ;(");
        require(tokenPrice <= msg.value, "That's not enough, sry ;(");
        require(whitelist[msg.sender]==true, "Who?");
            whitelist[msg.sender]=false;
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
    }
    function buyBorps(uint32 tokensNumber) public payable {
        require(mainSaleActive, "Maybe later");
        require(tokensNumber > 0, "U cant mint zero borps bro");
        require(tokensNumber <= maxTokensPerTransaction, "Save some for everyone else!");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Sry I dont have enough left ;(");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "That's not enough, sry ;(");
        for(uint32 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}