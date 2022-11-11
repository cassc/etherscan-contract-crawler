// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

import "../nft/TaipeNFT.sol";
import "../lib/TaipeLib.sol";
import "../polygon/IMintableERC721.sol";

contract EthereumTaipe is TaipeNFT, IMintableERC721 {
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
}