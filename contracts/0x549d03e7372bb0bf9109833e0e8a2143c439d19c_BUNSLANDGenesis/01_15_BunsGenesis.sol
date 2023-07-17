// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BUNSLANDGenesis is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address private bank = 0x74CaD1e8e7a81215857ce194540dA21d29Ae22a2;
    bool public hasSaleStarted = false;
    bool public hasPresaleStarted = false;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public constant bunsPrice = 0.07 ether;
    uint public constant MAX_SALE = 174; // 174
    uint public constant MAX_PRESALE = 76; // 76
    uint public constant MAX_EVERYTHING = MAX_SALE + MAX_PRESALE;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public presalerListPurchases;

    constructor() ERC721("BUNS.LAND Genesis", "BUNSG2") {}

    function addToWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!whitelist[entry], "DUPLICATE_ENTRY");

            whitelist[entry] = true;
        }   
    }

    function removeFromWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            whitelist[entry] = false;
        }
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

  function safeMint(address to, uint256 numBuns) public payable {
    	require(hasSaleStarted, "Sale has not started yet.");
        require(numBuns > 0 && numBuns <= 5, "You can mint 1 to 5 buns at a time.");
        require(msg.value >= bunsPrice * numBuns, "Not enough ETH sent; check the price!");
        require(publicAmountMinted + privateAmountMinted + numBuns <= MAX_EVERYTHING, "Not enough buns left. Try to decrease the amount of buns requested.");
        require(totalSupply() < MAX_EVERYTHING, "SOLD OUT."); 
 
        for (uint i = 0; i < numBuns; i++) {
            publicAmountMinted++;
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }
 
    function safePresaleMint(address to, uint256 numBuns) public payable {
      	require(hasPresaleStarted, "Presale has not started yet."); 
        require(numBuns == 1, "You can mint 1 bun at a time.");
        require(msg.value >= bunsPrice * numBuns, "Not enough ETH sent; check the price!");
        require(whitelist[msg.sender], "You do not own an origin bun. Please come back later for the sale.");
        require(privateAmountMinted + numBuns <= MAX_PRESALE, "Not enough buns left. Try to decrease the amount of buns requested.");
        require(presalerListPurchases[msg.sender] + numBuns <= 1, "You can only adopt 1 Genesis bun during presale.");
        require(privateAmountMinted < MAX_PRESALE, "Presale has SOLD OUT.");
 
        for (uint i = 0; i < numBuns; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function stopSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function startPresale() public onlyOwner {
        hasPresaleStarted = true;
    }

    function stopPresale() public onlyOwner {
        hasPresaleStarted = false;
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nfts.buns.land/bunsg2/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        require(payable(bank).send(_balance));
    }
}