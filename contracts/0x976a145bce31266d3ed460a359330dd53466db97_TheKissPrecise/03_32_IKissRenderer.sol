// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IKissRenderer is IERC165 {
    /**
    @notice Returns an image for an arbitrary seed.
     */
    function draw(bytes32 seed) external pure returns (string memory);

    /**
    @notice Returns an image for an arbitrary string, which should be hashed and
    propagated to draw(bytes32).
     */
    function draw(string memory seed) external pure returns (string memory);

    /**
    @notice Returns a full token JSON metadata object, with image, as a data
    URI.
     */
    function tokenURI(uint256 tokenId, bytes32 seed)
        external
        view
        returns (string memory);
}