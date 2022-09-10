// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TANG3PORT1 is ERC721, Ownable {
    using Counters for Counters.Counter;
    string public baseURI;
    bytes32 private root;
    uint256 public maxSupply = 2000;
    // Mapping for keeping track of which address minted already
    mapping(address => bool) public mintedAlready;

    Counters.Counter private _tokenIdCounter;

    constructor(bytes32 _root, string memory _initBaseURI) ERC721("TANG3PORT1", "TG3PT1") {
        root = _root;
        baseURI = _initBaseURI;
    }

    function safeMint(bytes32[] memory proof) public {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not part of Allowlist");
        require(!mintedAlready[msg.sender], "Minted already");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + 1 <= maxSupply, "Max token supply reached");
        mintedAlready[msg.sender] = true;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        return _baseURI();
    }
}