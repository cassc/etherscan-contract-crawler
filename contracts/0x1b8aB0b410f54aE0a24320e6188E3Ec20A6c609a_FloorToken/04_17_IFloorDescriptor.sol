// SPDX-License-Identifier: GPL-3.0

/// @title Interface for FloorDescriptor

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                            *
*    8888888888 888      .d88888b.   .d88888b.  8888888b.    *
*    888        888     d88P" "Y88b d88P" "Y88b 888   Y88b   *
*    888        888     888     888 888     888 888    888   *
*    8888888    888     888     888 888     888 888   d88P   *
*    888        888     888     888 888     888 8888888P"    *
*    888        888     888     888 888     888 888 T88b     *
*    888        888     Y88b. .d88P Y88b. .d88P 888  T88b    *
*    888        88888888 "Y88888P"   "Y88888P"  888   T88b   *
*                                                            *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

pragma solidity ^0.8.6;

interface IFloorDescriptor {
    event BaseURIUpdated(string baseURI);

    event ImageURIUpdated(string imageURI);

    event ExtUpdated(string ext);

    event DataURIToggled(bool enabled);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function imageURI() external returns (string memory);

    function ext() external returns (string memory);

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function setImageURI(string calldata imageURI) external;

    function setExt(string calldata ext) external;

    function tokenURI(uint256 tokenId, uint16 size) external view returns (string memory);

    function dataURI(uint256 tokenId, uint16 size) external view returns (string memory);
}