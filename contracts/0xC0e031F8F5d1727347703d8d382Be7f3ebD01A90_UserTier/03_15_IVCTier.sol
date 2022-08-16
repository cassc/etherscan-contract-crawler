// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct VCNFTTier {
    address nftContract;
    bytes32 traditionalTier;
    address[] spAllowedTokens;
    address[] spAllowedNFTs;
}

interface IVCTier {
    function getVCTier(address _vcTierNFT)
        external
        view
        returns (VCNFTTier memory);

    function getUserVCNFTTier(address _wallet)
        external
        view
        returns (VCNFTTier memory);
}