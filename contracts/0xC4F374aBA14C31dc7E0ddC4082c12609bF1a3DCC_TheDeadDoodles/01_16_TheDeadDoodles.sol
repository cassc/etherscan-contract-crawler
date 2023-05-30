// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

/// @custom:security-contact [email protected]
contract TheDeadDoodles is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _baseUri = "https://api.thedeaddoodles.com/metadata/";
    uint private _maxTokens = 9999;
    uint private _maxSingleMintAmount = 10;
    uint private _price = 0.03 ether;
    uint private _discountPrice = 0.02 ether;
    bool private _preSaleEnabled = false;
    bool private _publicSaleEnabled = false;

    mapping(address => bool) private _alreadyPreMinted;

    mapping(uint => address) private _frenContracts;
    uint private _numFrenContracts = 0;

    mapping(uint => address) private _preSaleContracts;
    uint private _numPreSaleContracts = 0;

    mapping(address => bool) private _whitelist;    

    constructor() ERC721("TheDeadDoodles", "TDD") {
        
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPreSale(bool enabled) public onlyOwner {
        _preSaleEnabled = enabled;
    }

    function setPublicSale(bool enabled) public onlyOwner {
        _publicSaleEnabled = enabled;
        _preSaleEnabled = false;
    }

    function setMaxTokens(uint maxTokens) public onlyOwner {
        _maxTokens = maxTokens;
    }

    function setBaseUri(string calldata baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function setPrice(uint price) public onlyOwner {
        _price = price;
    }

    function setDiscountPrice(uint price) public onlyOwner {
        _discountPrice = price;
    }

    function addFrenContract(address contractFren) public onlyOwner {
        _frenContracts[_numFrenContracts] = contractFren;
        _numFrenContracts++;
    }

    function setFrenContract(uint index, address theAddress) public onlyOwner {
        require(_frenContracts[index] != address(0), "No fren at index. :(");
        _frenContracts[index] = theAddress;
    }

    function addPresaleContract(address contractFren) public onlyOwner {
        _preSaleContracts[_numPreSaleContracts] = contractFren;
        _numPreSaleContracts++;
    }

    function setPreSaleContract(uint index, address theAddress) public onlyOwner {
        require(_preSaleContracts[index] != address(0), "No presale contract at index. :(");
        _preSaleContracts[index] = theAddress;
    }    

    function modifyWhitelist(address theAddress, bool isWhitelisted) public onlyOwner {
        _whitelist[theAddress] = isWhitelisted;
    }

    function addToWhitelist(address[] calldata addresses) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++){
            _whitelist[addresses[i]] = true;
        }
    }

    function ownerMint(address to, uint amount)
        public
        payable
        onlyOwner    
    {
        uint256 tokenId = _tokenIdCounter.current();

        require(tokenId + amount <= _maxTokens, "Not enough tokens remaining.");

        for(uint i = 0; i < amount; i++){
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function tokenCount()
        public
        view
        returns (uint)
    {
        return _tokenIdCounter.current();
    }

    function mint(address to, uint amount) 
        public 
        payable 
        whenNotPaused
    {
        require(msg.value > 0, "Value too small.");
        require(_preSaleEnabled || _publicSaleEnabled, "Sale has not yet started.");

        (bool toIsPreSaleEligible, bool discountEnabled) = destinationIsPreSaleEligible(to);
        if (_preSaleEnabled){
            require(toIsPreSaleEligible, "Public sale has not yet started.");
        }

        uint tokenId = _tokenIdCounter.current();

        require(tokenId + amount <= _maxTokens, "Not enough tokens remaining.");
        require(amount <= _maxSingleMintAmount, "Mint amount exceeds max.");

        uint mintPrice = _price;

        if (discountEnabled) {
            mintPrice = _discountPrice;
        }
        require(msg.value == amount * mintPrice, "Value incorrect.");

        if(_preSaleEnabled){
            _alreadyPreMinted[to] = true;
        }

        for(uint i = 0; i < amount; i++){
            _tokenIdCounter.increment();
            tokenId++;
            _safeMint(to, tokenId);
        }
    }

    function destinationIsPreSaleEligible(address to)
        public
        view
        returns (bool, bool)
    {
        if (_alreadyPreMinted[to]){
            if (addressGetsDiscount(to)){
                return (false, true);
            } else {
                return (false, false);
            }
        }

        if (addressGetsDiscount(to)){
            return (true, true);
        }

        for(uint i = 0; i < _numPreSaleContracts; i++){
            if (addressOwnsTokenAt(to, _preSaleContracts[i])){
                return (true, false);        
            }
        }        

        if (_whitelist[to]){
            return (true, false);
        }

        return (false, false);
    }

    function addressGetsDiscount(address to)
        public
        view
        returns (bool) 
    {
        for(uint i = 0; i < _numFrenContracts; i++){
            if (addressOwnsTokenAt(to, _frenContracts[i])){
                return true;             
            }
        }

        return false;
    }

    function addressOwnsTokenAt(address owner, address tokenContract)
        internal
        view
        returns (bool)
    {
        uint balanceOf = IERC721(tokenContract).balanceOf(owner);
        return balanceOf > 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(_baseUri, Strings.toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}