//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MigratorSimple {
    struct BatchTransfer {
        address registry;
        uint256[] ids;
    }

    function migrate721(
        address registry,
        uint256[] calldata ids,
        address to
    ) external {
        uint256 length = ids.length;
        for (uint256 i; i < length; i++) {
            IERC721(registry).transferFrom(msg.sender, to, ids[i]);
        }
    }

    function migrate721Batch(BatchTransfer[] calldata transfers, address to)
        external
    {
        uint256 length = transfers.length;
        uint256 idsLength;
        BatchTransfer memory batchTransfer;
        for (uint256 i; i < length; i++) {
            batchTransfer = transfers[i];
            idsLength = batchTransfer.ids.length;
            for (uint256 j; j < length; j++) {
                IERC721(batchTransfer.registry).transferFrom(
                    msg.sender,
                    to,
                    batchTransfer.ids[j]
                );
            }
        }
    }
}

interface IERC721 {
    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}