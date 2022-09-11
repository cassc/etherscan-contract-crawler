// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 //
    enum Imp {
        NONE,
        NFT,
        OPENSEA,
        SPLITTER
    }

    struct Royals {
        address[] accounts;
        uint256[] shares;
    }

    struct Royalties {
        Royals royals;
        uint256 royaltyInBasisPoints;
        Royals royalsFirstSale;
        uint256 royaltyInBasisPointsFirstSale;
    }

    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        string contractURI;
        string contractURIFirstSale;
    }

    struct NewNFTParams {
        NFTMetadata metadata;
        bytes32 nftSalt;
        address owner;
        uint256 totalSupply;
        uint256 premintStart;
        uint256 premintEnd;
        Royalties royalties;
    }

interface ICore {


    event NewNFT(
        address nft, 
        address openseaMinter, 
        address splitter, 
        address splitterFirstSale, 
        NewNFTParams params
    );

    function newNFT(NewNFTParams calldata params) external returns(address);
   
}