// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IErrorsAndEvents} from "./IErrorsAndEvents.sol";

import {Claim} from "./Structs.sol";

/**
 * @title ClaimableNftVault
 * @custom:version 1.0
 */
contract ClaimableNftVault is Pausable, ERC1155Holder, Ownable, ReentrancyGuard, IErrorsAndEvents {
    mapping(bytes => Claim) public claims;

    /// ===== ERC1155 Hooks =====

    function onERC1155Received(
        address operator,
        address,
        uint256 tokenId,
        uint256 value,
        bytes memory data
    ) public override whenNotPaused returns (bytes4) {
        bytes memory claimKey = getClaimKey(operator, msg.sender, tokenId);

        Claim storage claim = claims[claimKey];

        require(data.length == 32, "missing merkle root");

        if (claim.admin == address(0x0)) {
            claim.admin = operator;
            claim.supply = value;
        } else {
            claim.supply += value;
        }

        claim.merkleRoot = bytes32(data);

        emit ClaimableVaultAssetDeposited(claim.admin, msg.sender, tokenId, claim.supply, claim.merkleRoot);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        revert("batch transfer unsupported");
    }

    ///  ===== Core =====

    function extractClaimableAsset(bytes calldata claimKey) external nonReentrant {
        Claim storage claim = claims[claimKey];

        _validateClaimAdmin(claim.admin);

        (address _claimAdmin, address _tokenAddress, uint256 _tokenId) = unpackClaimKey(claimKey);

        uint256 supply = claim.supply;

        if (supply == 0) {
            revert InsufficientSupply();
        }

        claim.supply = 0;

        IERC1155(_tokenAddress).safeTransferFrom(address(this), _claimAdmin, _tokenId, supply, "");

        emit ClaimableVaultAssetDepleted(_claimAdmin, _tokenAddress, _tokenId);
    }

    function claimAsset(
        bytes calldata claimKey,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant whenNotPaused {
        if (amount == 0) {
            revert InvalidClaimAmount();
        }

        Claim storage claim = claims[claimKey];

        if (claim.admin == address(0x0)) {
            revert InvalidClaimKey();
        }

        if (claim.supply < amount) {
            revert InsufficientSupply();
        }

        mapping(address => bool) storage claimers = claim.claimers;

        if (claimers[msg.sender]) {
            revert CallerHasAlreadyClaimed();
        }

        (address _claimAdmin, address _tokenAddress, uint256 _tokenId) = unpackClaimKey(claimKey);

        _validateMerkleProof(_tokenAddress, amount, claim.merkleRoot, proof);

        claimers[msg.sender] = true;

        unchecked {
            claim.supply -= amount;
        }

        IERC1155(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId, amount, "");

        emit ClaimableVaultAssetClaimed(_claimAdmin, _tokenAddress, _tokenId, msg.sender, amount);

        if (claim.supply == 0) {
            emit ClaimableVaultAssetDepleted(_claimAdmin, _tokenAddress, _tokenId);
        }
    }

    function setClaimRoot(bytes calldata claimKey, bytes32 root) external whenNotPaused {
        Claim storage claim = claims[claimKey];

        _validateClaimAdmin(claim.admin);

        claim.merkleRoot = root;

        (address _claimAdmin, address _tokenAddress, uint256 _tokenId) = unpackClaimKey(claimKey);

        emit ClaimableVaultAssetMerkleRootUpdated(_claimAdmin, _tokenAddress, _tokenId, root);
    }

    /// ===== Read =====

    function getClaimKey(
        address claimAdmin,
        address contractAddress,
        uint256 tokenId
    ) public pure returns (bytes memory) {
        return abi.encode(claimAdmin, contractAddress, tokenId);
    }

    function unpackClaimKey(
        bytes calldata claimKey
    ) public pure returns (address claimAdmin, address contractAddress, uint256 tokenId) {
        return abi.decode(claimKey, (address, address, uint256));
    }

    /// ===== Owner =====
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /// ===== Internal =====

    function _validateClaimAdmin(address claimAdmin) internal view {
        if (msg.sender != claimAdmin) {
            revert InvalidClaimAdmin();
        }
    }

    function _validateMerkleProof(
        address tokenAddress,
        uint256 amount,
        bytes32 root,
        bytes32[] calldata proof
    ) internal view {
        bool isValidProof = MerkleProof.verify(
            proof,
            root,
            keccak256(abi.encodePacked(tokenAddress, msg.sender, amount))
        );

        if (!isValidProof) {
            revert InvalidClaimProof();
        }
    }
}