// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./FruitFarm.sol";


contract RSSFruits is  AccessControlEnumerable, ERC721URIStorage, ERC721Enumerable, ERC721Pausable, ERC721Burnable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(uint256 => uint256) internal idToFruit; // from 1 to FRUIT_COUNT
    mapping(uint256 => bool) internal fruitToMint;


    constructor() ERC721("RSS Fruits Token", "RFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControlEnumerable, ERC721Enumerable) returns (bool) {
       return super.supportsInterface(interfaceId);
    }    
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
 
    function pause() public virtual onlyRole(PAUSER_ROLE) {
        _pause();
    }
 
    function unpause() public virtual onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addAdmin(address newAdmin) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    function randFruitId(uint256 seed, uint256 newItemId) internal returns(uint256) {
        require(idToFruit[newItemId] == 0, "Token has been assigned fruit.");
        uint256 rand = uint256(keccak256(abi.encodePacked(seed)));
        uint256 fruitId = rand % (FruitFarm.FRUIT_COUNT + 1 - newItemId);
        uint j = 0;
        for (uint i = 1; i <= FruitFarm.FRUIT_COUNT; i++) {
            if (fruitToMint[i] == false)
                j++;
            if(j == fruitId + 1) {
                fruitToMint[i] = true;
                return i;
            }
        }
        return FruitFarm.FRUIT_COUNT + 1;
    }
    
    function awardFruit(address rss3er, uint256 _seed) onlyRole(MINTER_ROLE)
        public
        returns (uint256)
    {
        require(_tokenIds.current() < FruitFarm.FRUIT_COUNT, "ERC721: maximum number of tokens already minted.");
        uint256 seed = uint256(
            keccak256(abi.encodePacked(_seed, block.timestamp, msg.sender, _tokenIds.current()))
        );

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
       
        idToFruit[newItemId] = randFruitId(seed, newItemId);
        assert(idToFruit[newItemId] <= FruitFarm.FRUIT_COUNT);

        _mint(rss3er, newItemId);

        return newItemId;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyRole(MINTER_ROLE)
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function draw(uint256 tokenId) public view returns ( string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        string memory metadata = FruitFarm.harvest(idToFruit[tokenId]);
        return metadata;
    }
}