// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IERC721ABatchUpgradeable is IERC721AUpgradeable {
    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Transfers `id` tokens from `from` to one `to` address.
    /// @dev See {ERC721A.transferFrom}.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param ids The token IDs to transfer.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    /// @notice Safely transfers `id` tokens from `from` to one `to` address.
    /// @dev See {ERC721A.safeTransferFrom}.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param ids The token IDs to transfer.
    /// @param data The data to callback with.
    function batchSafeTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}