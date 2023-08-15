// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct DaoMetadataParam {
    uint256 startDrb;
    uint256 mintableRounds;
    uint256 floorPriceRank;
    uint256 maxNftRank;
    uint96 royaltyFee;
    string projectUri;
    uint256 projectIndex;
}

struct DaoMintInfo {
    uint32 daoMintCap;
    mapping(address minter => UserMintInfo) userMintInfos;
}

struct UserMintInfo {
    uint32 minted;
    uint32 mintCap;
}

struct DaoMintCapParam {
    uint32 daoMintCap;
    UserMintCapParam[] userMintCapParams;
}

struct UserMintCapParam {
    address minter;
    uint32 mintCap;
}

struct DaoETHAndERC20SplitRatioParam {
    uint256 canvasCreatorERC20Ratio;
    uint256 nftMinterERC20Ratio;
    uint256 daoFeePoolETHRatio;
    uint256 daoFeePoolETHRatioFlatPrice;
}