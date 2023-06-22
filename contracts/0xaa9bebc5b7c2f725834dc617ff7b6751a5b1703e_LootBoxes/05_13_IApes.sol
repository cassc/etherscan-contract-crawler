// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

interface IApes {
    function confirmChange(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}