// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "Ownable.sol";
import "MerkleProof.sol";

/**
 * @author Bruce Wang
 * @notice Pink Flamingo Social Club: Whitelist Management
 */
abstract contract Whitelisted is Ownable {
    /**
     * @notice Event to notify of changes
     */
    event Whitelist(bool on);

    /**
     * @notice Flag to enable/disable whitelisting
     */
    bool public whitelistOnly = true;

    /**
     * @notice Merkle root hash for whitelist addresses
     */
    bytes32 public merkleRoot;

    /**
     * @notice Change merkle root hash
     */
    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner {
        merkleRoot = merkleRootHash;
    }

    /**
     * @notice Toggle whitelistOnly state
     */
    function setWhitelistOnly(bool _whitelistOnly) external onlyOwner {
        require(
            _whitelistOnly != whitelistOnly,
            "Must be different to current value"
        );
        whitelistOnly = _whitelistOnly;
        emit Whitelist(_whitelistOnly);
    }

    /**
     * @notice Verify merkle proof of the address
     */
    modifier verifyWhitelist(bytes32[] calldata merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Not in Whitelist"
        );
        _;
    }

    /**
     * @notice Verify merkle proof of the address
     */
    modifier whenWhitelistOnly() {
        require(whitelistOnly, "Please use publicMint");
        _;
    }

    /**
     * @notice Verify merkle proof of the address
     */
    modifier whenNotWhitelistOnly() {
        require(!whitelistOnly, "Only open to Whitelist");
        _;
    }
}