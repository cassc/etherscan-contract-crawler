// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract UpTribe2022 is ERC721, Ownable {
    bytes32 public whitelistMerkleRoot;

    string private baseURI;

    constructor() ERC721("UP2022", "UP2022") {}

    function mint(address recipient, uint256 tokenId, bytes32[] calldata merkleProof) external {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(recipient, tokenId))), "[recipient address + tokenId] is not in whitelist.");
        _safeMint(recipient, tokenId);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}