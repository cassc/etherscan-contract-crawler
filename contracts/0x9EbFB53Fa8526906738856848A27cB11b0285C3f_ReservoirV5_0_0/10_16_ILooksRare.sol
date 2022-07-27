// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOrderTypes {
    struct MakerOrder {
        bool isOrderAsk;
        address signer;
        address collection;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isOrderAsk;
        address taker;
        uint256 price;
        uint256 tokenId;
        uint256 minPercentageToAsk;
        bytes params;
    }
}

interface ILooksRare {
    function transferSelectorNFT() external view returns (address);

    function matchAskWithTakerBidUsingETHAndWETH(
        IOrderTypes.TakerOrder calldata takerBid,
        IOrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchBidWithTakerAsk(
        IOrderTypes.TakerOrder calldata takerAsk,
        IOrderTypes.MakerOrder calldata makerBid
    ) external;
}

interface ILooksRareTransferSelectorNFT {
    function TRANSFER_MANAGER_ERC721() external view returns (address);

    function TRANSFER_MANAGER_ERC1155() external view returns (address);
}