// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICEABallonGlobal {
    struct NftInput {
        uint256 typeId;
    }

    struct Nft {
        uint256 id;
        uint256 typeId;
        address creator;
        uint256 block;
    }

    struct NftInfo {
        Nft nft;
        bool isExist;
        address owner;
    }
}