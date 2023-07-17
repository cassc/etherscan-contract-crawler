// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "Ownable.sol";
import "ERC721Enumerable.sol";
import "Counters.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    bytes32 private _root;
    string private _uri;
    mapping(address => bool) private _claimed;
    Counters.Counter private _nextId;

    constructor(string memory name, string memory symbol, string memory uri)
        ERC721(name, symbol)
    {
        _uri = uri;
    }

    function setURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function setRoot(bytes32 root) external onlyOwner {
        _root = root;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uri));
    }

   /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; ++i) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /**
     * @dev Claims/mints an NFT token if the sender is eligible to claim via the merkle proof.
     */
    function claim(bytes32[] memory proof) external {
        require(_root != 0, 'merkle root not set');

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(proof, _root, leaf), 'sender not eligible to claim');

        require(!_claimed[msg.sender], 'already claimed');
        _claimed[msg.sender] = true;

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(msg.sender, _nextId.current());
        _nextId.increment();
    }

    /**
     * @dev Burns `tokenId`. See OpenZeppelin ERC721 _burn.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}