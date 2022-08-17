// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";

import { IERC721ABatch } from "../interfaces/IERC721ABatch.sol";

/// @notice Simple ERC721A extension for batch transfers.
/// @author SerpentaIO
abstract contract ERC721ABatch is IERC721ABatch, ERC721A {
    /* ------------------------------------------------------------------------------------------ */
    /*                                      PUBLIC FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc IERC721ABatch
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external virtual {
        unchecked {
            for (uint256 i; i < ids.length; i++) {
                transferFrom(from, to, ids[i]);
            }
        }
    }

    /// @inheritdoc IERC721ABatch
    function batchSafeTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external virtual {
        unchecked {
            for (uint256 i; i < ids.length; i++) {
                safeTransferFrom(from, to, ids[i], data);
            }
        }
    }
}