// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721PepeMetadata.sol";
import "./ERC721PepeMinter.sol";


contract ERC721Pepe is ERC721, Ownable {
    address public minter;
    address public metadata;
    uint256 public tokenId = 1;

    // Mappings from imageHash to tokenId and vice versa
    mapping(uint256 => uint256) public imageHashTokenIds;
    mapping(uint256 => uint256) public tokenIdImageHashes;

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
        string memory uri = IERC721PepeMetadata(metadata).tokenURI(hash);
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
}