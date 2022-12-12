// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import "../base/BaseClaimNFT.sol";
import "./IDiscountClaimNFT.sol";
import "./DiscountClaimNFTStorage.sol";

error DiscountClaimingNotAllowed();

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract DiscountClaimNFT is IDiscountClaimNFT, BaseClaimNFT, DiscountClaimNFTStorage {
    using MerkleProofUpgradeable for bytes32[];

    event DiscountMerkleRootChanged(bytes32 discountMerkleRoot);

    function __DiscountClaimNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri,
        uint256 maxEditionTokens,
        uint256 claimValue,
        bytes32 discountMerkleRoot
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __MintNFTContract_init_unchained();
        __BaseClaimNFTContract_init_unchained(maxEditionTokens, claimValue);
        __DiscountClaimNFTContract_init_unchained(discountMerkleRoot);
    }

    function __DiscountClaimNFTContract_init_unchained(bytes32 discountMerkleRoot) internal onlyInitializing {
        _discountMerkleRoot = discountMerkleRoot;
    }

    function setDiscountMerkleRoot(bytes32 discountMerkleRoot) external onlyOperator {
        _discountMerkleRoot = discountMerkleRoot;
        emit DiscountMerkleRootChanged(discountMerkleRoot);
    }

    function isDiscountClaimAllowed(bytes32[] calldata discountProof, uint256 claimValue) external view returns (bool) {
        return _isDiscountClaimAllowed(discountProof, claimValue);
    }

    function _discountClaim(
        Edition edition,
        Size size,
        bytes32[] calldata discountProof,
        uint256 claimValue
    ) internal returns (uint256 tokenId) {
        if (!_isDiscountClaimAllowed(discountProof, claimValue)) revert DiscountClaimingNotAllowed();
        if (msg.value < claimValue) revert InvalidClaimValue(msg.value);

        tokenId = _checkedClaim(edition, size);

        _discountClaimedTokens[msg.sender] = true;
    }

    function _isDiscountClaimAllowed(bytes32[] calldata discountProof, uint256 claimValue)
        internal
        view
        returns (bool)
    {
        if (_discountClaimedTokens[msg.sender]) return false;

        bytes32 leaf = _getDiscountMerkleLeaf(claimValue);

        return discountProof.verify(_discountMerkleRoot, leaf);
    }

    function _getDiscountMerkleLeaf(uint256 claimValue) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.chainid, address(this), msg.sender, claimValue));
    }
}