// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IgmRenderer {
    function applyStyle(uint16 id) external;

    function addAddress(uint16 tokenId, address newAddress) external;

    function tokenUri(uint16 id) external view returns (string memory);
}