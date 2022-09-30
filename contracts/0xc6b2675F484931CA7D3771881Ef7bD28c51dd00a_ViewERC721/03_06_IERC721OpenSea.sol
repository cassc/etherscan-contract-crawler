// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @dev See {IERC721Metadata}
interface IERC721OpenSea is IERC721Metadata {
    /// @dev See https://docs.opensea.io/v2.0/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
}