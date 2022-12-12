// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import "../base/BaseClaimNFT.sol";
import "./IWhitelistClaimNFT.sol";
import "./WhitelistClaimNFTStorage.sol";

error WhitelistClaimingNotAllowed();

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract WhitelistClaimNFT is IWhitelistClaimNFT, BaseClaimNFT, WhitelistClaimNFTStorage {
    using MerkleProofUpgradeable for bytes32[];

    event WhitelistMerkleRootChanged(bytes32 whitelistMerkleRoot);

    function __WhitelistClaimNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri,
        uint256 maxEditionTokens,
        uint256 claimValue,
        bytes32 whitelistMerkleRoot
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __MintNFTContract_init_unchained();
        __BaseClaimNFTContract_init_unchained(maxEditionTokens, claimValue);
        __WhitelistClaimNFTContract_init_unchained(whitelistMerkleRoot);
    }

    function __WhitelistClaimNFTContract_init_unchained(bytes32 whitelistMerkleRoot) internal onlyInitializing {
        _whitelistMerkleRoot = whitelistMerkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 whitelistMerkleRoot) external onlyOperator {
        _whitelistMerkleRoot = whitelistMerkleRoot;
        emit WhitelistMerkleRootChanged(whitelistMerkleRoot);
    }

    function whitelistClaim(
        Edition edition,
        Size size,
        bytes32[] calldata whitelistproof
    ) external payable returns (uint256 tokenId) {
        if (!_isWhitelistClaimAllowed(whitelistproof)) revert WhitelistClaimingNotAllowed();
        if (msg.value < _claimValue) revert InvalidClaimValue(msg.value);

        tokenId = _checkedClaim(edition, size);
    }

    function isWhitelistClaimAllowed(bytes32[] calldata whitelistproof) external view returns (bool) {
        return _isWhitelistClaimAllowed(whitelistproof);
    }

    function _isWhitelistClaimAllowed(bytes32[] calldata whitelistproof) internal view returns (bool) {
        return whitelistproof.verify(_whitelistMerkleRoot, _getWhitelistMerkleLeaf());
    }

    function _getWhitelistMerkleLeaf() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.chainid, address(this), msg.sender));
    }
}