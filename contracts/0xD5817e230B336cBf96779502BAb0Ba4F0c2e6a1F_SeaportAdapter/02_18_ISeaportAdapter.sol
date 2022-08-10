// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISeaportAdapter {

    function seaportBuy(
        bytes calldata _calldata,
        address recipient,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address payToken,
        uint256 payAmount

    ) external payable;

    function seaportAccetpOffer(
        bytes calldata _calldata,
        address acceptToken,
        address recipient,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external;
}