// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./HexStrings.sol";
import "./interfaces/IERC721PepeMetadata.sol";


contract ERC721PepeMetadata is Ownable {
    using HexStrings for uint256;

    // Mappings to override tokenURI
    mapping(uint256 => string) public metadataOverrides;

    event MetadataOverridden(uint256 indexed tokenHash, string oldUri, string newUri, string reason);

    address public pepeContract;

    string public baseURI = "";

    constructor(string memory baseURI_) {
        baseURI = baseURI_;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPepeContract(address _pepeContract) external onlyOwner {
        pepeContract = _pepeContract;
    }

    // Override a token's tokenURI
    function overrideMetadata(uint256 hash, string memory uri, string memory reason) external onlyOwner {
        emit MetadataOverridden(hash, tokenURI(hash), uri, reason);
        metadataOverrides[hash] = uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * https://docs.ipfs.tech/concepts/hashing/
     */
    function tokenURI(uint256 hash) public view returns (string memory) {
        // check for uri override, and return that instead
        if (bytes(metadataOverrides[hash]).length != 0) return metadataOverrides[hash];

        return string(abi.encodePacked(baseURI, hash.uint2hexstr(), ".json"));
    }
}