// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FudFarm is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintLand(address indexed sender, uint256 startWith, uint256 times);

    //supply counters 
    uint256 public totalLands;
    uint256 public totalCount = 10000;
    uint256 public totalPublic = 7777;
    //token Index tracker 


    uint256 public maxBatch = 10;
    uint256 public price = 30000000000000000;

    //string
    string public baseURI;

    //bool
    bool private started;

    //constructor args 
    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    //erc721 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function devMint(uint256 _times) public onlyOwner {
        require(totalLands >= totalPublic, "Must sell out.");
        require(totalPublic +_times <= totalCount, "exceed max supply.");
        emit MintLand(_msgSender(), totalPublic+1, _times);
        for(uint256 i=0; i<_times; i++) {
            _mint(_msgSender(), 1 + totalPublic++);
        }
    }

    function mint(uint256 _times) payable public {
        require(started, "Land sale ain't started, partner.");
        require(_times > 0 && _times <= maxBatch, "Too many lands");
        require(totalLands + _times <= totalPublic, "ALL BOUGHT OUT");
        require(msg.value == _times * price, "value error, please check price.");
        payable(owner()).transfer(msg.value);
        emit MintLand(_msgSender(), totalLands+1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + totalLands++);
        }
    }  
}