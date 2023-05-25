// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC721BeforeTokenTransferHandler.sol";

abstract contract ERC721OperatorFilter is Context, Ownable, ERC721 {
     /// @notice Reference to the handler contract for transfer hooks
    address public beforeTokenTransferHandler;

    /**
     * Sets the before token transfer handler
     *
     * @param handlerAddress  Address to the transfer hook handler contract
     */
    function setBeforeTokenTransferHandler(
        address handlerAddress
    ) external onlyOwner {
        beforeTokenTransferHandler = handlerAddress;
    }

    /**
     * @notice Handles any pre-transfer actions
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        if (beforeTokenTransferHandler != address(0)) {
            IERC721BeforeTokenTransferHandler handlerRef = IERC721BeforeTokenTransferHandler(
                    beforeTokenTransferHandler
                );
            handlerRef.beforeTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                tokenId,
                batchSize
            );
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}