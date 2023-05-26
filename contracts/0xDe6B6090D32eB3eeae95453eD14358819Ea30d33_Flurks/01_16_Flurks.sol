// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Flurks is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
  
    uint256 private tokenPrice = 85000000000000000; //0.085 ETH
    uint256 private constant nftsNumber = 5000; //37 Reserved for giveaways and influencers
    uint256 private constant nftsPublicNumber = 4963; //first 3 reserved for original stonetoss NFT holders
    uint32 private maxTokensPerTransaction = 10;
    
    address private constant mommy =    0x37432B25a8198752140de1A8fb1A64E4181e4a7e;
    address private constant babyBoy1 = 0x811427462234445bc011d2DE167CAE26302Bd135;
    address private constant babyBoy2 = 0x3B43652Bedf79244df8cf67be659D8e4CE089A61;
    address private constant babyBoy3 = 0x3fc08378e78AE5143d45151Eb84f395aa00c6876;

    bool public saleActive;
    bool public uriUnlocked = true;
    bool public supplyCapped;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Flurks by Stonetoss", "FLURK") {
        _tokenIdCounter.increment();
        _tokenIdCounter.increment();
        _tokenIdCounter.increment();
        _tokenIdCounter.increment();
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        require(uriUnlocked, "The token URI has been locked forever.");
        _baseURIPrefix = baseURIPrefix;
    }
    function _baseURI() internal view override returns(string memory) {
        return _baseURIPrefix;
    }

    function lockURI() public onlyOwner {
        uriUnlocked = false;
    }
    function capSupply() public onlyOwner {
        supplyCapped = true;
    }

    function safeMint(address to) public onlyOwner {
        require(!supplyCapped, "The supply has been capped");
        require(_tokenIdCounter.current() <= nftsNumber, "There aren't any more left.");
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function flurkCount() public view returns(uint256 a){
        return Counters.current(_tokenIdCounter);
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
    returns(bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns(string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint cut = balance.div(2);
        uint split = cut.div(3);
        payable(mommy).transfer(cut);
        payable(babyBoy1).transfer(split);
        payable(babyBoy2).transfer(split);
        payable(babyBoy3).transfer(split);
    }


    function flipSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function mintGiveawayFlurks(address to, uint256 tokenId) public onlyOwner {
        require(!supplyCapped, "The supply has been capped");
        require(tokenId > nftsPublicNumber, "You cant give away flurks from the public sale");
        require(tokenId <= nftsNumber, "That exceeds the total supply");
        _safeMint(to, tokenId);
    }
    
        function mintOGFlurks(address to, uint256 tokenId) public onlyOwner {
        require(tokenId <= 3, "Only the first 3 are reserved for OG holders");
        require(tokenId >0, "That ID doesn't exist");
        _safeMint(to, tokenId);
    }

    function buyFlurks(uint tokensNumber) public payable {
        require(!supplyCapped, "The supply has been capped");
        require(saleActive, "Maybe later");
        require(tokensNumber > 0, "Please enter an amount greater than zero.");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber + 1, "The number you're trying to buy exceeds the remaining supply!");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "You didn't include enough ETH with your transaction");

            require(tokensNumber <= maxTokensPerTransaction, "You can only buy 10 Flurks at a time.");

        for (uint i = 0; i < tokensNumber; i++) {
            if (_tokenIdCounter.current() <= nftsPublicNumber) {
                _safeMint(msg.sender, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
    }
}