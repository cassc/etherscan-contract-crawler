// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheOneEyedSmiley is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant maxItems = 10000;
    uint256 public constant price = 0.025 ether;
    uint256 public constant priceAfterSale = 0.05 ether;
    uint256 public presaleRemaining = 1000;
    uint256 public reservedRemaining = 350;

    string baseURI = "https://api.nftmarketservice.com/token/toes/";
    string baseContractURI = "https://api.nftmarketservice.com/token/toes/";
    uint8 public charLimit = 32;
    bool public namingAllowed = false;
    bool public changesLocked = false;

    /************ EVENTS **************/
    event NameChanged(uint256 _tokenId, string _name);
    event NamingStateChanged(bool _namingAllowed);
    event NamingCharacterLimitChanged(uint8 _charLimit);
    event ChangesLocked(bool _changesLocked);
    /**********************************/

    constructor() ERC721("TheOneEyedSmiley", "TOES") {}

    //For OpenSea
    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function currentTokenIdCounter() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setBaseURI(string memory _newBaseURI) public virtual onlyOwner {
        require(!changesLocked, "Changes are locked");
        baseURI = _newBaseURI;
    }

    function lockChanges() public virtual onlyOwner {
        changesLocked = true;
        emit ChangesLocked(true);
    }

    function setBaseContractURI(string memory _newContractURI) public virtual onlyOwner {
        require(!changesLocked, "Changes are locked");
        baseContractURI = _newContractURI;
    }


    function reserve(uint num, address _to) public onlyOwner {
        require(num > 0, "Reserve number must be greater than zero");
        require(_tokenIdCounter.current() + num <= maxItems, "Reserve would exceed max supply of items");
        require(reservedRemaining >= num, "Reserve would exceed limit");

        uint i;
        for (i = 0; i < num; i++) {
            _tokenIdCounter.increment();
            _safeMint(_to, _tokenIdCounter.current());
            reservedRemaining = reservedRemaining - 1;
        }
    }

    function setCharacterLimit(uint8 _charLimit) external onlyOwner {
        charLimit = _charLimit;
        emit NamingCharacterLimitChanged(_charLimit);
    }

    function toggleNaming(bool _namingAllowed) external onlyOwner {
        namingAllowed = _namingAllowed;
        emit NamingStateChanged(_namingAllowed);
    }

    function nameNFT(uint256 _tokenId, string memory _name) external payable {
        require(namingAllowed, "Naming is disabled");
        require(balanceOf(msg.sender) > 0, "The address has no associated items");
        require(ownerOf(_tokenId) == msg.sender, "Only the owner can change the NFT name");
        require(bytes(_name).length <= charLimit, "Exceeded characters limit");
        emit NameChanged(_tokenId, _name);
    }


    function mint(uint256 mintCount) public payable {

        uint256 currentPrice = price;

        //Limit presale purchases
        if (presaleRemaining > 0) {
            require((balanceOf(msg.sender) + mintCount) <= 4, "Exceeded the limit of presale items per address");
            require(presaleRemaining >= mintCount, "Exceeded the number of items for presale");
        } else {
            currentPrice = priceAfterSale;
            require(mintCount <= 10, "Exceeded the limit of items to be minted at once");
        }

        require(msg.value >= (currentPrice * mintCount), "Value below current price");
        require((totalSupply() + mintCount + reservedRemaining) <= maxItems, "Purchase would exceed max supply of items");

        for (uint256 i = 0; i < mintCount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());

            if (presaleRemaining > 0) {
                presaleRemaining = presaleRemaining - 1;
            }

        }

    }


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
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

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        (bool sent,) = msg.sender.call{value : balance}("");
        require(sent, "Failed to send Ether");
    }
}