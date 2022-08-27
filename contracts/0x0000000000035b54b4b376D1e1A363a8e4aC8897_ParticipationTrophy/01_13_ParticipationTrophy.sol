// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error ParticipationTrophy__AccountNotAllowed();
error ParticipationTrophy__AlreadyMinted();

//         ======
//       _|      |_
//      ((|      |))
//       \|      |/
//        \__  __/
//          _)(_
//         /____\
//        /______\

contract ParticipationTrophy is ERC1155, ERC1155Burnable, Ownable, ReentrancyGuard {
    /// EVENTS ///

    /// @notice Emitted when a user account mints new tokens.
    /// @param minter The minter account address.
    event Mint(address indexed minter);

    /// @notice Emitted when Merkle root is set.
    /// @param newMerkleRoot The new Merkle root.
    event SetMerkleRoot(bytes32 newMerkleRoot);

    /// @notice Emitted when a new token URI is set.
    /// @param newURI The new token URI.
    event SetURI(string newURI);

    /// PUBLIC STORAGE ///

    /// @notice Trophy type.
    uint256 public constant PARTICIPATION = 0;

    /// @notice Whether an account has minted.
    mapping(address => bool) public minted;

    /// @notice Token name.
    string public name;

    /// @notice Token symbol.
    string public symbol;

    /// INTERNAL STORAGE ///

    /// @dev The merkle root of mint allow list.
    bytes32 internal merkleRoot;

    constructor(string memory uri_) ERC1155(uri_) {
        name = "Participation Trophy";
        symbol = "PT";
    }

    /// @notice Mint new tokens.
    ///
    /// @dev Emits a {Mint} event.
    ///
    /// @dev Requirements:
    /// - Caller account must be allowed to mint.
    /// - Caller account can only mint once.
    ///
    /// @param merkleProof The merkle proof of caller being allowed to mint.
    function mint(bytes32[] calldata merkleProof) external nonReentrant {
        if (!MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert ParticipationTrophy__AccountNotAllowed();
        }
        if (minted[msg.sender]) {
            revert ParticipationTrophy__AlreadyMinted();
        }

        minted[msg.sender] = true;

        _mint(msg.sender, PARTICIPATION, 1, "");
        emit Mint(msg.sender);
    }

    /// @notice Set the Merkle root of mint allow list.
    ///
    /// @dev Emits a {SetMerkleRoot} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newMerkleRoot The new Merkle root.
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
        emit SetMerkleRoot(newMerkleRoot);
    }

    /// @notice Set the token URI.
    ///
    /// @dev Emits a {SetURI} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newURI The new token URI.
    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
        emit SetURI(newURI);
    }
}