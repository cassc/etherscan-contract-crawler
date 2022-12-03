//SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract FHOY is ERC721, Ownable, ERC721Burnable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 500;
    uint256 public totalSupply;
    string private baseTokenUri;

    bool public pause;

    mapping(address => uint256) public totalMints;
    mapping(address => uint256) private _freeWalletMints;
    
    constructor(string memory _URI) ERC721("FRENS.HOUSE ART", "FRENS.ART") {
        baseTokenUri = _URI;
        _tokenIdCounter.increment();
 
    }

    function mint() external {
        require(!pause, "Contract is Paused");
        require(totalSupply + 1 <= MAX_SUPPLY, "All gone fren!");
        require(_freeWalletMints[_msgSender()] <= 1, "You have already minted fren");
         _freeWalletMints[_msgSender()] += totalSupply;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        totalSupply++;
    }

    function airDrop(address[] memory _airdrops) external onlyOwner {
        require(!pause, "Contract Paused");
        require((totalSupply + _airdrops.length) <= MAX_SUPPLY, "Max supply exceeded");
        for(uint i = 0; i < _airdrops.length; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint( _airdrops[i], tokenId);
            totalSupply++;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
  
        return baseTokenUri;
    }


    //Only Owner Functions
    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function togglePause() external onlyOwner {
        pause= !pause;
    }

    function withdraw() external onlyOwner {
        (bool delivered, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(delivered);
    }
}