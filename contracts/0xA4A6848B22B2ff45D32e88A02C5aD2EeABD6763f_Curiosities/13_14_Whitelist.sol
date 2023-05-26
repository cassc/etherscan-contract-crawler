// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @author tempest-sol
abstract contract Whitelist is Ownable {
    using MerkleProof for *;

    bool public whitelistActive;

    bytes32 private merkle;

      ////////////////////
     ///    Events    ///
    ////////////////////
    event MerkleUpdatead(bytes32 merkle);

    function updateMerkle(bytes32 _merkle) external onlyOwner {
        require(merkle != _merkle, "merkle_already_set");
        merkle = _merkle;
        emit MerkleUpdatead(_merkle);
    }

    function verifyWhitelist(bytes32 _leaf, bytes32[] calldata proof) private view returns (bool) {
        return proof.verify(merkle, _leaf);
    }

    function leaf(string memory payload) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload));
    }

    modifier onlyWhitelisted(bytes32[] calldata proof) {
        if(!whitelistActive) {
            _;
            return;
        }
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(verifyWhitelist(leaf(payload), proof), "not_whitelisted");
        _;
    }
}