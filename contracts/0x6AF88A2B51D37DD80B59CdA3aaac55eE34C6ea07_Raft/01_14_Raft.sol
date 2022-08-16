// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Raft contract
/// @custom:juice 100%
/// @custom:security-contact [email protected]
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation
contract Raft is ERC721, Pausable, Ownable, ERC721Burnable {    
    using Counters for Counters.Counter;

    string public baseURI;
    uint256 public maxSupply;
    mapping (address => bool) public minters;

    Counters.Counter private _tokenIdCounter;

    constructor()
        ERC721("Raft", "RAFT")
    {
        baseURI = "https://8si3p8yv1h.execute-api.us-west-2.amazonaws.com/metadata/castaways/raft/";
        maxSupply = 100;
    }

    // shish was here
    function mintRaft()
        public
        whenNotPaused
    {
        require(_tokenIdCounter.current() < maxSupply, "Exceeds max supply");
        require(balanceOf(_msgSender()) == 0, "Exceeds claim limit");
        require(minters[_msgSender()] == false, "Exceeds claim limit");
        
        minters[_msgSender()] = true;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function setBaseURI(string calldata newBaseURI)
        external
        onlyOwner
    {
        baseURI = newBaseURI;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _tokenIdCounter.current();
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}