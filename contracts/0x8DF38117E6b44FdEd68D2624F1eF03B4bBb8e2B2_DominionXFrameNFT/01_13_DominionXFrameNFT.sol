// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DominionXFrameNFT is ERC721, Ownable {
    constructor() ERC721("DominionX: Level 2", "DXL2") {}

    using Strings for uint256;
    string private _baseTokenURI;
    bytes32 public merkleRoot;
    bool public isMintActive;
    mapping(address => bool) public claimed;

    /**
     * @dev Mint a single token for the connected wallet if the `merkleProof` is valid with the correct `tokenId`
     *
     * Requirements:
     * - merkle proof is valid
     * - The user has not already claimed
     */
    function mint(uint256 tokenId, bytes32[] calldata merkleProof) public {
        require(isMintActive, "Minting is not active");
        require(!claimed[msg.sender], "Already claimed");
        bytes32 merkleLeaf = _merkleLeafForUserAndTokenId(msg.sender, tokenId);
        require(
            MerkleProof.verify(merkleProof, merkleRoot, merkleLeaf),
            "Not authorized to mint"
        );
        _mint(msg.sender, tokenId);
        claimed[msg.sender] = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // onlyOwner functions

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setIsMintActive(bool active) external onlyOwner {
        isMintActive = active;
    }

    // Internal functions

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _merkleLeafForUserAndTokenId(address user, uint256 tokenId)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, tokenId));
    }
}