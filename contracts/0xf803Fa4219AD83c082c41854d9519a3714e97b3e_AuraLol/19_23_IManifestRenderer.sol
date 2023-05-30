// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "../TokenData.sol";

interface IManifestRenderer {

    /// @notice Returns the metadata uri for a given token
    function tokenURI(uint256 tokenId, TokenData memory tokenData)
        external
        pure
        returns (string memory);
}