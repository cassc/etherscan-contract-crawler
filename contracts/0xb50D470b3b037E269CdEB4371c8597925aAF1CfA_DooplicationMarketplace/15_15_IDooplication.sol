// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDooplication {
    function dooplicate(
        uint256 dooplicatorId,
        address dooplicatorVault,
        uint256 tokenId,
        address tokenContract,
        address tokenVault,
        bytes8 addressOnTheOtherSide,
        bytes calldata data
    ) external;

    function dooplicationActive(address) external view returns (bool);

    function contractApproved(
        address tokenContract
    ) external view returns (bool);

    function tokenDooplicated(
        uint256 tokenId,
        address tokenContract
    ) external view returns (bool);
}