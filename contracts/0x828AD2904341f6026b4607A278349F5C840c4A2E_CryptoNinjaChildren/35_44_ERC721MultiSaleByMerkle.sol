// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721MultiSaleByMerkle.sol";
import "../ERC721MultiSale.sol";

abstract contract ERC721MultiSaleByMerkle is
    IERC721MultiSaleByMerkle,
    ERC721MultiSale
{
    bytes32 internal _merkleRoot;

    // ==================================================================
    // Modifier
    // ==================================================================
    modifier hasRight(
        uint248 amount,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, allowedAmount));
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
        uint248 amount,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) internal virtual hasRight(amount, allowedAmount, merkleProof) {
        _claim(amount, allowedAmount);
    }

    function _exchange(
        uint256[] calldata burnTokenIds,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    )
        internal
        virtual
        hasRight(uint248(burnTokenIds.length), allowedAmount, merkleProof)
    {
        _exchange(burnTokenIds, allowedAmount);
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