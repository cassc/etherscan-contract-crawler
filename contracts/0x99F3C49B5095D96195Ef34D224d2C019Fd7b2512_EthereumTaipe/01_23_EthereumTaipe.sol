// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

import "../nft/TaipeNFT.sol";
import "../lib/TaipeLib.sol";
import "../polygon/IMintableERC721.sol";
import "../opensea/DefaultOperatorFilterer.sol";

contract EthereumTaipe is TaipeNFT, IMintableERC721, DefaultOperatorFilterer {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(address childChainManager) TaipeNFT() {
        _setupRole(PREDICATE_ROLE, childChainManager);
    }

    function _insideTokenMintCap(uint tokenId)
        internal
        pure
        override
        returns (bool)
    {
        return tokenId >= 1 && tokenId <= TaipeLib.TOTAL_TIER_1;
    }

    // polygon bridge

    function exists(uint tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint tokenId)
        external
        override
        onlyRole(PREDICATE_ROLE)
    {
        _mint(to, tokenId);
    }

    function mint(
        address user,
        uint tokenId,
        bytes calldata
    ) external override onlyRole(PREDICATE_ROLE) {
        _mint(user, tokenId);
    }

    // opensea filter

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}