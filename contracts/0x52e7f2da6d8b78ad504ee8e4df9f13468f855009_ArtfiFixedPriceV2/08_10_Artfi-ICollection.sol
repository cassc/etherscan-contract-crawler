//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ArtfiICollectionV2 {
    struct NftData {
        string uri;
        uint256 fractionId;
        address[] creators;
        uint256[] royalties;
        bool isFirstSale;
    }

    struct MintData {
        string uri;
        uint256 fractionId;
        address seller;
        address buyer;
        address[] creators;
        uint256[] royalties;
        bool isFirstSale;
    }

    struct BridgeData {
        address buyer;
        address otherTokenAddress;
        string uri;
        bool locked;
    }

    struct Payout {
        address currency;
        address[] refundAddresses;
        uint256[] refundAmounts;
    }

    struct WhiteList {
        address user;
        bool value;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isWhiteListed(address caller_) external view returns (bool);

    function isQuantityAllowed(uint256 quantity) external view returns (bool);

    function isArtfiCollectionContract() external pure returns (bool);

    function whiteListUpdate(address user, bool value) external;

    function updateWhiteListBatch(WhiteList[] memory objects) external;

    function exists(uint256 tokenId_) external view returns (bool exists_);

    function getNftInfo(
        uint256 tokenId_
    ) external view returns (NftData memory nfts_);

    function getOwner() external view returns (address _owner);

    // function bridgeNft(
    //     uint256 tokenId_,
    //     address otherTokenAddress,
    //     address owner
    // ) external;

    // function adminMintBridge(
    //     BridgeData memory bridgeData_
    // ) external returns (uint256 tokenId_);

    function mint(
        MintData memory mintData_
    ) external returns (uint256 tokenId_);

    function transferNft(address from_, address to_, uint256 tokenId_) external;

    function transferStakedNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;

    function setNftData(uint256 tokenId_, MintData memory mintData_) external;
}