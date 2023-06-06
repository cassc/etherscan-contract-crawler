// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WojakKingdom is ERC721, ERC721URIStorage, Pausable, Ownable {

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
    uint private constant maxTokensPerTransaction = 25;
    uint256 private tokenPrice = 5 * 10 ** 16; //Cost set to 0.05 ETH
    uint256 private constant nftsNumber = 4269; 
    uint256 private constant nftsPublicNumber = 4250;
    address private constant withdrawAddressOne = 0x528483BD8D2963C30d303C53B2a1D0C2e512EC07;
    address private constant withdrawAddressTwo = 0x06a032A6C7675Ffd40411c5399A206C0b71aB29a;
    address private constant withdrawAddressThree = 0xB56AfCee1Ac559bbB2BF0D1d4ff02205654C60dc;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("WojakKingdom", "WJKK") {
        _tokenIdCounter.increment();
    }

    function currentSupply() public view returns (uint256)
    {
        return _tokenIdCounter.current();
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintGiveawayWojaks(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Sale has not ended yet!");
        _safeMint(to, tokenId);
    }

    function buyWojaks(uint tokensNumber) whenNotPaused public payable {
        require(tokensNumber > 0, "Number of mints must be atleast 1");
        require(tokensNumber <= maxTokensPerTransaction, "Exceeded max tokens per mint");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "No more tokens left to be minted");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Not enough sent ETH, price is 0.05 per token");
        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint cut = balance.div(3);
        payable(withdrawAddressOne).transfer(cut);
        payable(withdrawAddressTwo).transfer(cut);
        payable(withdrawAddressThree).transfer(cut);

    }
}