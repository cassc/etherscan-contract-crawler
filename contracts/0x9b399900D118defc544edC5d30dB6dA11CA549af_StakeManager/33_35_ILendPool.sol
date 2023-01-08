// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface ILendPool {
    function deposit(
        address reserve,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) external returns (uint256, bool);
}