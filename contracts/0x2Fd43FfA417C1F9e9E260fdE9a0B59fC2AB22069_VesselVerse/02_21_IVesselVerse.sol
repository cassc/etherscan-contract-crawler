// SPDX-License-Identifier: GPL-3.0

/// @title Interface for IVesselVerse

pragma solidity ^0.8.17;

import "erc721a/contracts/interfaces/IERC721A.sol";

interface IVesselVerse is IERC721A {
    event VesselVerseCreated(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    event MinterLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function supplyLeft() external returns (bool);
}