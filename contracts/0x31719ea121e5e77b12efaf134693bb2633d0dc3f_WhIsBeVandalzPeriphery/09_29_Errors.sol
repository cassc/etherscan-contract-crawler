// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Errors {
    error WhisbeVandalz__InvalidCollection(address);
    error WhisbeVandalz__EightTiersRequired(uint256);
    error ERC721RandomlyAssignVandalzTier__UnavailableTierTokens(uint256);
    error WhisbeVandalz__MintNotAvailable();
    error WhisbeVandalz__PublicMintUpToTwoPerWallet();
    error WhisbeVandalz__NoGroupTier15678Group();
    error WhisbeVandalz__NoGroupTier135678Group();
    error WhisbeVandalz__NoGroupTier5678Group();
    error WhisbeVandalzPeriphery__EightTiersRequired(uint256);
    error WhisbeVandalzPeriphery__InvalidCollection(address);
    error WhisbeVandalzPeriphery__PublicMintUpToTwoPerWallet();
    error WhisbeVandalzPeriphery__MintNotAvailable();
    error WhisbeVandalzPeriphery__NoGroupTier135678Group();
    error WhisbeVandalzPeriphery__NoGroupTier15678Group();
    error WhisbeVandalzPeriphery__PublicMintOver();
    error WhisbeVandalzPeriphery__IncorrectPublicSalePrice();
}