// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IERC721PepeMetadataV3.sol";
import "./ERC721PepeMinterV3.sol";


contract ERC721PepeInfinite is IERC165, ERC721, Ownable {
    address public minter;
    address public metadata;
    uint256 public tokenId = 42070;

    // Mappings from imageHash to tokenId and vice versa
    mapping(uint256 => uint256) public imageHashTokenIds;
    mapping(uint256 => uint256) public tokenIdImageHashes;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(string memory name_, string memory symbol_, address minterContract, address metadataContract) ERC721(name_, symbol_) {
        minter = minterContract;
        metadata = metadataContract;
    }

    function setPepeMinter(address minterContract) external onlyOwner {
        minter = minterContract;
    }

    function setPepeMetadata(address metadataContract) external onlyOwner {
        metadata = metadataContract;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        // send the tokenId and hash to the metadata contract for further processing
        uint256 hash = tokenIdImageHashes[_tokenId];
        string memory uri = IERC721PepeMetadataV3(metadata).tokenURI(hash);
        return uri;
    }

    function mint(address to, uint256 imageHash) external {
        require(msg.sender == minter, "must be minter");

        // check imageHash doesn't already exist
        require(imageHashTokenIds[imageHash] == 0, "hash exists");

        // store imageHash <=> tokenId
        imageHashTokenIds[imageHash] = tokenId;
        tokenIdImageHashes[tokenId] = imageHash;

        _mint(to, tokenId++);
    }

    function burn(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "must be owner");

        // look up imageHash from tokenId
        uint256 imageHash = tokenIdImageHashes[_tokenId];

        // clean up mappings
        delete imageHashTokenIds[imageHash];
        delete tokenIdImageHashes[_tokenId];

        _burn(_tokenId);
    }

    function updateMetadata(uint256 _tokenId) external onlyOwner {
        require(tokenIdImageHashes[_tokenId] > 0, "invalid tokenId");
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