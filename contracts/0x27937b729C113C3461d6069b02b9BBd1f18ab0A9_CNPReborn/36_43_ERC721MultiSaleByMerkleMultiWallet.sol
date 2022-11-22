// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721MultiSaleByMerkleMultiWallet.sol";
import "../ERC721MultiSaleMultiWallet.sol";

abstract contract ERC721MultiSaleByMerkleMultiWallet is
    IERC721MultiSaleByMerkleMultiWallet,
    ERC721MultiSaleMultiWallet
{
    bytes32 internal _merkleRoot;

    // ==================================================================
    // Modifier
    // ==================================================================
    modifier hasRight(
        uint256 userId,
        uint256 amount,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) {
        bytes32 node = keccak256(
            abi.encodePacked(userId, msg.sender, allowedAmount)
        );
        require(
            MerkleProof.verifyCalldata(merkleProof, _merkleRoot, node),
            "invalid proof."
        );
        _;
    }

    // ==================================================================
    // Function
    // ==================================================================
    function _claim(
        uint256 userId,
        uint256 amount,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) internal virtual hasRight(userId, amount, allowedAmount, merkleProof) {
        _claim(userId, amount, allowedAmount);
    }

    function _exchange(
        uint256 userId,
        uint256[] calldata burnTokenIds,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    )
        internal
        virtual
        hasRight(userId, burnTokenIds.length, allowedAmount, merkleProof)
    {
        _exchange(userId, burnTokenIds, allowedAmount);
    }

    function _setCurrentSale(Sale calldata sale, bytes32 merkleRoot) internal {
        _merkleRoot = merkleRoot;
        _setCurrentSale(sale);
    }

    // ------------------------------------------------------------------
    // unused super function
    // ------------------------------------------------------------------
    function setCurrentSale(
        Sale calldata /** sale */
    ) external pure virtual {
        revert("no use.");
    }
}