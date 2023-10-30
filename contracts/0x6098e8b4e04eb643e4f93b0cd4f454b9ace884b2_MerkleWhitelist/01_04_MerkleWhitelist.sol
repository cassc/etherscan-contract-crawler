// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";

import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";

contract MerkleWhitelist is IWhitelist, Owned {
    bytes32 public whitelistMerkleRoot;

    constructor(bytes32 initialRoot, address initialOwner) Owned(initialOwner) {
        emit NewWhitelistRoot(whitelistMerkleRoot = initialRoot);
    }

    /// @notice Change whitelist signer
    function setRoot(bytes32 newRoot) external onlyOwner {
        emit NewWhitelistRoot(whitelistMerkleRoot = newRoot);
    }

    /// @dev Validates the provided merkle proof `proof` for `member`.
    function isWhitelisted(address member, bytes32[] calldata proof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(member));
        return MerkleProofLib.verify(proof, whitelistMerkleRoot, leaf);
    }
}