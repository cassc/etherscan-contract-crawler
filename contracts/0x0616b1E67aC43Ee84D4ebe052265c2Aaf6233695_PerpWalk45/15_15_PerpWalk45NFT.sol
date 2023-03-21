// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PerpWalk45 is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant MAX_TOKENS = 4500;

    // BaseTokenURI + BaseContractURI
    string public _baseTokenURI;
    string public _baseContractURI;
    string private _baseTokenExtension;
    

    constructor() ERC721("PerpWalk45", "PERPWALK") {}

    function safeMint(address to) public {
        require(_tokenIdCounter.current() < MAX_TOKENS, "Maximum tokens limit reached");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev sets the extension for tokens (.json) as example
     */
    function setTokenExtension(string memory extension) public onlyOwner {
        _baseTokenExtension = extension;
    }    
  
    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), _baseTokenExtension));
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }
        
    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseContractURI));
    }

    function setBasecontractURI(string memory __baseContractURI) public onlyOwner {
        _baseContractURI = __baseContractURI;
    }
}