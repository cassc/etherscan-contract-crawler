pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PropertyDeed  is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => bytes32) private _tokenContentHashes;

    constructor() ERC721("Property Deed", "PROP") Ownable() {}

    function tokenizeProperty(address owner, string memory tokenURI, bytes32 contentHash)
        external
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newPropertyId = _tokenIds.current();
        _mint(owner, newPropertyId);
        _setTokenURI(newPropertyId, tokenURI);
        _setTokenHash(newPropertyId, contentHash);

        return newPropertyId;
    }

    /**
     * Returns the stored content has of the token with id `tokenId`
     * @param tokenId the id of the token to query
     * @return hash of the content generated via generateContentHash
     */
    function tokenHash(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId), "PropertyDeed: URI query for nonexistent token");
        return _tokenContentHashes[tokenId];
    }

    /**
     * Generated the keccak256 hash of the input string along with a salt.
     * @param input the content to hash
     * @return hash of the content
     */
    function generateHash(string memory input) external pure returns(bytes32) {
        return keccak256(abi.encode("PropertyDeed", input));
    }

    function _setTokenHash(uint256 tokenId, bytes32 _tokenContentHash) internal {
        require(_exists(tokenId), "PropertyDeed: URI query for nonexistent token");
        _tokenContentHashes[tokenId] = _tokenContentHash;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _tokenContentHashes[tokenId];
    }
}