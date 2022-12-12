// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./IClaimNFT.sol";

import "./public/PublicClaimNFT.sol";
import "./whitelist/WhitelistClaimNFT.sol";
import "./discount/DiscountClaimNFT.sol";

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract ClaimNFT is IClaimNFT, PublicClaimNFT, WhitelistClaimNFT, DiscountClaimNFT {
    function __ClaimNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri,
        uint256 maxEditionTokens,
        uint256 claimValue,
        bytes32 whitelistMerkleRoot,
        bytes32 discountMerkleRoot
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __MintNFTContract_init_unchained();
        __BaseClaimNFTContract_init_unchained(maxEditionTokens, claimValue);
        __PublicClaimNFTContract_init_unchained();
        __WhitelistClaimNFTContract_init_unchained(whitelistMerkleRoot);
        __DiscountClaimNFTContract_init_unchained(discountMerkleRoot);
        __ClaimNFTContract_init_unchained();
    }

    function __ClaimNFTContract_init_unchained() internal onlyInitializing {}

    function discountPublicClaim(
        Edition edition,
        Size size,
        bytes32[] calldata discountProof,
        uint256 claimValue
    ) external payable returns (uint256 tokenId) {
        if (!_publicClaimAllowed) revert PublicClaimingNotAllowed();
        tokenId = _discountClaim(edition, size, discountProof, claimValue);
    }

    function discountWhitelistClaim(
        Edition edition,
        Size size,
        bytes32[] calldata whitelistProof,
        bytes32[] calldata discountProof,
        uint256 claimValue
    ) external payable returns (uint256 tokenId) {
        if (!_isWhitelistClaimAllowed(whitelistProof)) revert WhitelistClaimingNotAllowed();
        tokenId = _discountClaim(edition, size, discountProof, claimValue);
    }
}