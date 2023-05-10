// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface VatLike {
    function urns(bytes32, address) external view returns (uint256 ink, uint256 art);

    function ilks(
        bytes32
    )
        external
        view
        returns (
            uint256 art, // Total Normalised Debt      [wad]
            uint256 rate, // Accumulated Rates         [ray]
            uint256 spot, // Price with Safety Margin  [ray]
            uint256 line, // Debt Ceiling              [rad]
            uint256 dust // Urn Debt Floor             [rad]
        );

    function gem(bytes32, address) external view returns (uint256); // [wad]

    function can(address, address) external view returns (uint256);

    function dai(address) external view returns (uint256);

    function frob(bytes32, address, address, address, int256, int256) external;

    function hope(address) external;

    function move(address, address, uint256) external;

    function fork(bytes32, address, address, int256, int256) external;
}