// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SequentialMintBase.sol";
import "./ClaimPeriodBase.sol";
import "../access/InitializableOwnable.sol";
import "../../initializable/IMerkleRootInitializer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AddressHasAlreadyClaimed();
error InvalidProof();
error MerkleRootAlreadyInitialized();
error MerkleRootHasNotBeenInitialized();
error MerkleRootCannotBeZero();
error MintedQuantityMustBeGreaterThanZero();

/**
 * @title MerkleWhitelistMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with merkle-proof based whitelist minting capabilities.
 * @dev Inheriting contracts must implement `_safeMintToken` and implement EIP-165 support as shown:
 *
 * function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
 *     return
 *     interfaceId == type(IMerkleRootInitializer).interfaceId ||
 *     super.supportsInterface(interfaceId);
 *  }
 *
 */
abstract contract MerkleWhitelistMint is InitializableOwnable, ClaimPeriodBase, SequentialMintBase, ReentrancyGuard, IMerkleRootInitializer {

    /// @dev This is the root ERC-721 contract from which claims can be made
    bytes32 private merkleRoot;

    /// @dev Mapping that tracks whether or not an address has claimed their whitelist mint
    mapping (address => bool) private whitelistClaimed;

    /// @dev Initializes the merkle root containing the whitelist.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the merkle root has already been initialized.
    /// Throws when the specified merkle root is zero.
    function initializeMerkleRoot(bytes32 merkleRoot_) public override onlyOwner {
        if(merkleRoot != bytes32(0)) {
            revert MerkleRootAlreadyInitialized();
        }

        if(merkleRoot_ == bytes32(0)) {
            revert MerkleRootCannotBeZero();
        }

        merkleRoot = merkleRoot_;
        _initializeNextTokenIdCounter();
    }

    /// @notice Mints the specified quantity to the calling address if the submitted merkle proof successfully verifies the reserved quantity for the caller in the whitelist.
    ///
    /// Throws when the claim period has not opened.
    /// Throws when the claim period has closed.
    /// Throws if a merkle root has not been set.
    /// Throws if the caller has already successfully claimed.
    /// Throws if the submitted merkle proof does not successfully verify the reserved quantity for the caller.
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof_) external nonReentrant {
        _requireClaimsOpen();

        bytes32 merkleRootCache = merkleRoot;

        if(merkleRootCache == bytes32(0)) {
            revert MerkleRootHasNotBeenInitialized();
        }

        if(whitelistClaimed[_msgSender()]) {
            revert AddressHasAlreadyClaimed();
        }

        if(!MerkleProof.verify(merkleProof_, merkleRootCache, keccak256(abi.encodePacked(_msgSender(), quantity)))) {
            revert InvalidProof();
        }

        whitelistClaimed[_msgSender()] = true;
        _mintBatch(_msgSender(), quantity);
    }

    /// @notice Returns the merkle root
    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    /// @notice Returns true if the account already claimed their whitelist mint, false otherwise
    function isWhitelistClaimed(address account) external view returns (bool) {
        return whitelistClaimed[account];
    }

    /// @dev Batch mints the specified quantity to the specified address.
    /// Throws if quantity is zero.
    /// Throws if `to` is a smart contract that does not implement IERC721 receiver.
    function _mintBatch(address to, uint256 quantity) private {

        if(quantity == 0) {
            revert MintedQuantityMustBeGreaterThanZero();
        }

        uint256 tokenIdToMint = getNextTokenId();
        unchecked {
            _advanceNextTokenIdCounter(quantity);

            for(uint256 i = 0; i < quantity; ++i) {
                _safeMintToken(to, tokenIdToMint + i);
            }
        }
    }

    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use safe mint, or something equivalent
    /// The minting function should throw if `to` is address(0) or `to` is a contract that does not implement IERC721Receiver.
    function _safeMintToken(address to, uint256 tokenId) internal virtual;
}