// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
    function listItem(
        address _contractNFT,
        uint256 _tokenId,
        address _contractERC20,
        uint256 _price
    ) external;

    function listBulkItems(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _amount,
        address _contractERC20,
        uint256 _price
    ) external virtual;

    function buyItem(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _storeId,
        uint256 _amount
    ) external payable virtual;

    function updatePriceItem(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _storeId,
        uint256 _amount
    ) external virtual;


    function cancelItem(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _storeId
    ) external virtual;
}