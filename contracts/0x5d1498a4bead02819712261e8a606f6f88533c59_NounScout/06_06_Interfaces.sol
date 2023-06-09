// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface INounsAuctionHouseLike {
    struct Auction {
        uint256 nounId;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        bool settled;
    }

    function auction() external view returns (Auction memory);

    function settleCurrentAndCreateNewAuction() external;
}

interface INounsSeederLike {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }
}

interface INounsDescriptorLike {
    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

interface INounsTokenLike {
    function descriptor() external view returns (address);

    function seeds(
        uint256 nounId
    ) external view returns (INounsSeederLike.Seed memory);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

interface ENSReverseResolver {
    function setName(string memory) external returns (bytes32);
}