// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PepeDreams is IERC165, ERC721, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 5000;
    uint256 public nextTokenId = 1;
    uint256 public maxMintsPerAddress = 5;
    mapping(address => uint256) public mintCounts;
    string public baseURI;
    bool public mintEnabled = false;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(string memory _baseUri) ERC721("Pepe Dreams", "PEPEDREAMS") {
        baseURI = _baseUri;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleMint() public onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function mint() public {
        require(mintEnabled, "Mint is disabled");
        require(nextTokenId <= maxSupply, "Pepe Dreams has minted out!");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        require(mintCounts[msg.sender] < maxMintsPerAddress, "Already minted max for this address");
        mintCounts[msg.sender] += 1;
        _mint(msg.sender, nextTokenId++);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        return bytes(baseURI).length > 0 ?
        string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
        : '';
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    function updateMetadata(uint256 _tokenId) external onlyOwner {
        require(_tokenId < nextTokenId, "invalid tokenId");
        emit MetadataUpdate(_tokenId);
    }

    function batchUpdateMetadata(uint256 fromTokenId, uint256 toTokenId) external onlyOwner {
        require(fromTokenId <= toTokenId, "invalid range");
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function batchUpdateMetadata(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit MetadataUpdate(tokenIds[i]);
        }
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        // ERC-4906: EIP-721 Metadata Update Extension
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}