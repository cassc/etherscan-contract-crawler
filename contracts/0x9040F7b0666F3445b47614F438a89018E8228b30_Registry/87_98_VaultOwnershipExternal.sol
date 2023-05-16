// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultOwnershipInternal } from './VaultOwnershipInternal.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';

import { Constants } from '../lib/Constants.sol';

import { SolidStateERC721, ERC721BaseInternal, ERC165Base } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

contract VaultOwnershipExternal is
    SolidStateERC721,
    VaultOwnershipInternal,
    VaultBaseInternal
{
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        super._beforeTokenTransfer(from, to, tokenId);

        // If minting just return
        if (from == address(0)) {
            return;
        }
        if (tokenId == _MANAGER_TOKEN_ID) {
            require(to == _manager(), 'must use changeManager');
        }
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}