/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IThirdExchangeOfferCheckerFeature {

    struct SeaportOfferCheckInfo {
        address conduit;
        bool conduitExists;
        uint256 balance;
        uint256 allowance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct LooksRareOfferCheckInfo {
        uint256 balance;
        uint256 allowance;
        bool isExecutedOrCancelled;
    }

    function getSeaportOfferCheckInfo(
        address account,
        address erc20Token,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (SeaportOfferCheckInfo memory info);

    function getLooksRareOfferCheckInfo(
        address account,
        address erc20Token,
        uint256 accountNonce
    ) external view returns (LooksRareOfferCheckInfo memory info);
}