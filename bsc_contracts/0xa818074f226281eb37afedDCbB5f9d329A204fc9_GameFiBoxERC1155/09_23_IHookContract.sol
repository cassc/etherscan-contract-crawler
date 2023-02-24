// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

interface IHookContract {
    function onBoxOpened(
        address caller,
        uint256 tokenId,
        uint256 amount
    ) external returns (uint256 entropy);
}