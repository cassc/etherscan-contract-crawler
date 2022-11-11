//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <0.9.0;

interface IHumanToYouth {
    enum NFTReleaseStatus {
        DISABLED,
        WHITELIST_MINT,
        OPEN_MINT
    }

    struct NFTRelease {
        NFTReleaseStatus status;
        bool revealed;
        bool whitelistOpen;
        uint8 supplyPercentage;
        uint256 whitelistCost;
        uint256 publicCost;
        bytes32 merkleRoot;
    }

    struct FreeMintData {
        bool allowed;
        bool minted;
    }
}