// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract M14 is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private supply;

    string public baseURI = "";
    string public uriSuffix = ".json";    
    string public hiddenMetadataUri;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 250;
    uint256 public cost = 0.01 ether;

    bool public revealed = false;
    

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    constructor() ERC721("Mission14", "M14") {
        setHiddenMetadataUri("ipfs://QmSfqtZU8gixcDG8RYE9GXms1suz6SsCaFQHU74Z3DMD8C");
        _mintLoop(msg.sender, 250);
    }
    

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mintOneNFT() public payable mintCompliance(1) {
        require(msg.value >= cost, "Insufficient funds!");
        _mintLoop(msg.sender, 1);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }
  
    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _mintLoop(_receiver, _mintAmount);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = supply.current();
        supply.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
            : "";
    }
    

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal mintCompliance(_mintAmount) {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function changeBaseUri(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}