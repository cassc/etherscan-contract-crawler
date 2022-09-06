// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import { IERC721ABatchUpgradeable } from "../interfaces/old/IERC721ABatchUpgradeable.sol";

/// @notice Simple ERC721A extension for batch transfers.
/// @author SerpentaIO
abstract contract ERC721ABatchUpgradeable is IERC721ABatchUpgradeable, ERC721AUpgradeable {
    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

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