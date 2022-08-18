// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MetaHellClub is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    uint256 public maxSupply = 6666;
    string public baseURI; 
    string public notRevealedUri = "";
    string public baseExtension = ".json";
    bool public revealed = true;
    uint256 _price = 0.005 ether;  

    Counters.Counter private _tokenIds;

    constructor(string memory uri)
        ERC721("Meta Hell Club", "MHC")
    {
        setBaseURI(uri);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
    _price = _newPrice;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _amount) external payable {
        require(_amount > 0, "MHC: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "MHC: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "MHC: Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function mintInternal() internal {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
    }

    function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }
}