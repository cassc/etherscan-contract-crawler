// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct SellList {
    address seller;
    address token;
    uint256 tokenId;
    uint256 amountOfToken;
    uint256 amountofTokenSold;
    uint256 startTime;
    uint256 deadline;
    uint256 price;
    bool isSold;
    bool protocolSell;
}

interface ITTMarketplace {
    function listBatchTeamNFT(
        uint256[] memory _tokenIds,
        uint256[] memory _amountOfTokens,
        uint256[] memory _prices,
        uint256 _startTime,
        uint256 _deadline
    ) external returns (bool);

    function sales(uint256 _sellId) external returns (SellList memory);

    function listTeamNFT(
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _price,
        uint256 _startTime,
        uint256 _deadline
    ) external returns (bool);

    function buyTeamNFT(
        uint256 _sellId,
        uint256 _quantity
    ) external returns (uint256);

    function buyBatchTeamNFT(
        uint256[] memory _sellIds,
        uint256[] memory _quantitys,
        bool _allowPartial
    ) external returns (uint256);

    function cancelList(uint256 _sellId) external returns (bool);
}