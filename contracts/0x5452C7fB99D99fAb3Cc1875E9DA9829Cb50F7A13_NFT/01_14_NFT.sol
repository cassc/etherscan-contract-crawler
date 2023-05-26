// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    bytes32 public merkleRoot;
    uint256 public MAX_SUPPLY = 10000;
    Counters.Counter private _tokenCount;
    mapping(address => bool) _minted;

    constructor(
        bytes32 _merkleRoot
    ) ERC721("The Genesis RSS3 Avatar NFT", "The Genesis RSS3 Avatar NFT") {
        merkleRoot = _merkleRoot;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenCount.current();
    }

    function hasMinted(address account) public view returns (bool) {
        return _minted[account];
    }

    function mint(address to, uint256 tokenId, bytes32[] calldata merkleProof) public {
        require(!_exists(tokenId), "TokenId not available");
        require(!_minted[to], "Already minted");
        require(tokenId <= MAX_SUPPLY, "Max supply exceeded");

        // verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(tokenId, to));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof');

        // set minted flag
        _minted[to] = true;

        // mint
        _safeMint(to, tokenId);
        _tokenCount.increment();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "The Genesis RSS3 Avatar NFT #',
                        Strings.toString(tokenId),
                        '", "description": "The Genesis RSS3 Avatar NFT is a collection of 10,000 unique ',
                        'avatars meticulously designed to identify RSS3 community members."',
                        ', "image": "ipfs://QmSX9QiwjTGBk5m22UscTg3vrbMwUfFsmxVzMH57hkPD5U/',
                        Strings.toString(tokenId),
                        '.png"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
}