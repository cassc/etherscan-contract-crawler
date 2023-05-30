//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

 

contract BerehyniaNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds = Counters.Counter(1);
    
    uint public constant MAX_SUPPLY = 2402;
    uint public constant PRICE = 0.05 ether;
    uint public constant MAX_PER_ACCOUNT = 15;
    uint public constant MAX_PER_MINT = 5;
    
    string public baseTokenURI;

    bool public saleIsActive = false;

    mapping(address=>uint) private mintedAmount;
    
    constructor(string memory baseURI) ERC721("BerehyniaNFT", "BRHN") {
        setBaseURI(baseURI);
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(tokenId < MAX_SUPPLY, "tokenId outside collection bounds");

        return _exists(tokenId);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(saleIsActive, "Sale is not active yet");
        require(totalMinted.add(_count) < MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
        require(mintedAmount[msg.sender].add(_count) <= MAX_PER_ACCOUNT, "Too many NFTs requested");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }

        mintedAmount[msg.sender] = mintedAmount[msg.sender].add(_count);
    }
    
    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function mintedAlready(address _owner) external view returns (uint) {
        return mintedAmount[_owner];
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}