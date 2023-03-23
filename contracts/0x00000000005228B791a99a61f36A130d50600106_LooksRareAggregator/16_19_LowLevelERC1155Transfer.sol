// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC1155} from "../interfaces/generic/IERC1155.sol";

// Errors
import {ERC1155SafeTransferFromFail, ERC1155SafeBatchTransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC1155Transfer
 * @notice This contract contains low-level calls to transfer ERC1155 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC1155Transfer {
    /**
     * @notice Execute ERC1155 safeTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     * @param amount Amount to transfer
     */
    function _executeERC1155SafeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ERC1155SafeTransferFromFail();
        }
    }

    /**
     * @notice Execute ERC1155 safeBatchTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenIds Array of tokenIds to transfer
     * @param amounts Array of amounts to transfer
     */
    function _executeERC1155SafeBatchTransferFrom(
        address collection,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(
            abi.encodeCall(IERC1155.safeBatchTransferFrom, (from, to, tokenIds, amounts, ""))
        );

        if (!status) {
            revert ERC1155SafeBatchTransferFromFail();
        }
    }
}