// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Author: @sssobeit
contract Endlesstate is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    string private baseURI;

    uint PRICE = 0 ether;

    // MAX_AMOUNT
    uint maxSupply;
    uint maxBatchSize;


    constructor(uint _price) ERC721("Endlesstate", "E-State") {
        setBaseUri("ipfs://QmRPSubNW7AiKqEWQRHvdEq6m9qYFzddxEXSqMqS4AZJFj/");

        maxBatchSize = 100;
        maxSupply = 10000;
        PRICE = _price;
        /*transferOwnership(0xaa81a993EF8Aa3eE4EF4a20426126f2F6A3cF9d8);*/
        _tokenId.increment();
    }

    function mint(uint _count, address _to) public payable {


        require(!paused(), "PAUSED ");
        require(_count > 0, "mint at least one token");
        require(_tokenId.current() + _count <= maxSupply, "not enough tokens left");
        require(_count <= maxBatchSize, "MAX BATCH SIZE");
        require(msg.value >= _count * PRICE || msg.sender == owner(), "MAX BATCH SIZE");

        for (uint i = 0; i < _count; i++){
            uint256 tokenId = _tokenId.current();
            _tokenId.increment();
            _safeMint(_to, tokenId);
        }
    }

    function mintMoreAddress(address[] calldata users) public payable onlyOwner {

        require(_tokenId.current() + users.length <= maxSupply, "not enough tokens left");

        for (uint i = 0; i < users.length; i++){

            uint256 tokenId = _tokenId.current();
            _tokenId.increment();
            _safeMint(users[i], tokenId);
        }

    }

    // view total supply
    function getTotalSupply() view public returns(uint) {
        return _tokenId.current();
    }

    // URI
    function setBaseUri(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    // UTILS
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

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
}