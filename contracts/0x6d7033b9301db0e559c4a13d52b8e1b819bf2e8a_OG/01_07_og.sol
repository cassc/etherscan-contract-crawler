// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OG is ERC20, ERC20Burnable {
    bytes32 public immutable merkleRoot;
    mapping(address => bool) public hasClaimed;

    struct Proof {
        address to;
        uint256 value;
        bytes32[] proof;
    }

    error AlreadyClaimed();
    error NotInMerkle();

    constructor() ERC20("OG", "OG") {
        merkleRoot = 0xe7f44253b1ea3bde8cc8ceffa36337779391544a847609070f0a7434b6d7a2e6;
    }

    event Claim(address indexed to, uint256 value);

    function claim(Proof calldata proof) external {
        if (hasClaimed[proof.to]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(proof.to, proof.value)))
        );
        bool isValidLeaf = MerkleProof.verify(proof.proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        hasClaimed[proof.to] = true;

        _mint(proof.to, proof.value);
        emit Claim(proof.to, proof.value);
    }
}