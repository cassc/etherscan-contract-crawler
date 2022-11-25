// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

pragma solidity ^0.8.15;

contract NFFi is ERC721URIStorage, ERC2981, Ownable {
    using Strings for uint256;
    
    uint256 public totalSupply;
    uint256 public MAX_SUPPLY;
    bool public isSupplyFrozen;
    bool public isMetadataFrozen;

    constructor(
        address _royaltyAddress,
        uint96 _royaltyFee
    ) ERC721("NFFi", "GYOMOU") {
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }
    
    function mint(string memory _URI) external onlyOwner {
        require(!isSupplyFrozen, "GyomouNFT: Supply already frozen");
        _safeMint(msg.sender, totalSupply);
        _setTokenURI(totalSupply, _URI);
        totalSupply++;
    }

    function multiMint(uint256 _quantity, string[] memory _URIs) external onlyOwner {
        require(!isSupplyFrozen, "GyomouNFT: Supply already frozen");
        require(_quantity == _URIs.length, "GyomouNFT: Number mismatch");

        uint256 supply = totalSupply;

        for (uint256 i; i < _quantity; i++) {
            _safeMint(msg.sender, supply + i);
            _setTokenURI(supply + i, _URIs[i]);
        }

        totalSupply += _quantity;
    }

    function airdropMint(address _to, string memory _URI) external onlyOwner {
        require(!isSupplyFrozen, "GyomouNFT: Supply already frozen");
        _safeMint(_to, totalSupply);
        _setTokenURI(totalSupply, _URI);
        totalSupply++;
    }

    function setNewTokenURI(uint256 _tokenId, string memory _newURI) external onlyOwner {
        require(!isMetadataFrozen, "GyomouNFT: Metadata already frozen");
        require(_exists(_tokenId), "GyomouNFT: Nonexistent token");
        _setTokenURI(_tokenId, _newURI);
    }
    
    function setRoyalty(address _royaltyAddress, uint96 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    function setFreezeSupply() external onlyOwner {
        require(!isSupplyFrozen, "GyomouNFT: Supply already frozen");
        isSupplyFrozen = true;
        MAX_SUPPLY = totalSupply;
    }

    function setFreezeMetadata() external onlyOwner {
        require(!isMetadataFrozen, "GyomouNFT: Metadata already frozen");
        isMetadataFrozen = true;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0x0), "GyomouNFT: New owner is the zero address");
        _transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId) || ERC721.supportsInterface(_interfaceId);
    }
}