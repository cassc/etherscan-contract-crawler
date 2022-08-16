// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct SingleSPTierData {
    uint256 ltv;
    bool singleToken;
    bool multiToken;
    bool singleNft;
    bool multiNFT;
}

struct NFTTierData {
    address nftContract;
    bool isTraditional;
    address spToken; // strategic partner token address - erc20
    bytes32 traditionalTier;
    uint256 spTierId;
    address[] allowedNfts;
    address[] allowedSuns;
}

interface IGovNFTTier {
    function getUserNftTier(address _wallet)
        external
        view
        returns (NFTTierData memory nftTierData);

    function getSingleSpTier(uint256 _spTierId)
        external
        view
        returns (SingleSPTierData memory);
}