// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Erc721.sol";
import "./utils/Strings.sol";

contract OpenPiano is ERC721 {
    using Strings for uint256;

    uint256 public immutable maxSupply;

    string public baseMetadataURI;

    string public contractURI;

    uint256 public tokenIndex = 1;

    event ChangedMetadata(
      string indexed newBaseMetadataURI
    );

    constructor (
      string memory _name,
      string memory _symbol,
      uint256 _maxSupply,
      string memory _contractURI
    ) ERC721(_name, _symbol) {
      maxSupply = _maxSupply;
      _safeMint(_msgSender(), 0);
      contractURI = _contractURI;
    }

    modifier onlyTokenIdZeroOwner() {
      require(ownerOf(0) == _msgSender(), 'not owner of tokenId: 0');
      _;
    }

    modifier onlyUnderMaxSupply(uint256 mintingAmount) {
      require(tokenIndex + mintingAmount <= maxSupply, 'exceeded max supply');
      _;
    }

    function setBaseMetadataURI(string memory _baseMetadataURI) public onlyTokenIdZeroOwner {
      baseMetadataURI = _baseMetadataURI;
      emit ChangedMetadata(_baseMetadataURI);
    }

    function _baseURI() override internal view virtual returns (string memory) {
      return baseMetadataURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function mint(address[] calldata addresses) onlyUnderMaxSupply(addresses.length) onlyTokenIdZeroOwner public {
      for (uint i = 0; i < addresses.length; ++i) {
        // mint token
        _safeMint(addresses[i], tokenIndex);
        // increment
        tokenIndex++;
      }
    }
}