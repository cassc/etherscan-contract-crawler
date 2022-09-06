// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract GraveStoneAbstract is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PEOPLE_ROLE = keccak256("PEOPLE_ROLE");
    Counters.Counter private _tokenIdCounter;

    struct LockState {
        uint256 tokenId;
        bool locked;
        uint256 expTime;
    }

    mapping(uint256 =>bool) public isBuryMap;
    mapping(uint256 =>LockState) public lockStateMap;
    

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _mint(address to) internal virtual; 
    function _mintWithLock(address to, uint256 expTime) internal virtual; 

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        _mint(to);
    }

    function safeMintWithLock(address to, uint256 expTime) public onlyRole(MINTER_ROLE) {
        _mintWithLock(to, expTime);
    }

    function isbury(uint256 tokenId) public view returns(bool){
       return isBuryMap[tokenId];
    }

    function bury(uint256 tokenId) public onlyRole(PEOPLE_ROLE) whenNotBury(tokenId){
       isBuryMap[tokenId] = true;
    }
    function unbury(uint256 tokenId) public onlyRole(PEOPLE_ROLE) whenBury(tokenId){
       isBuryMap[tokenId] = false;
    }

    function isLocked(uint256 tokenId) public view returns(bool){
        return lockStateMap[tokenId].locked && lockStateMap[tokenId].expTime>block.timestamp;
    }

    modifier whenNotBury(uint256 tokenId) {
      require(!isBuryMap[tokenId], "it has bean used");
      _;
    }
    modifier whenBury(uint256 tokenId) {
      require(isBuryMap[tokenId], "it has not bean used");
      _;
    }
    modifier whenNotLocked(uint256 tokenId) {
      require(!isLocked(tokenId), "locked");
      _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        whenNotBury(tokenId)
        whenNotLocked(tokenId)
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.metagrave.co/graveStone/";
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
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}