// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultParentTransport } from './VaultParentTransport.sol';
import { VaultParentInvestor } from './VaultParentInvestor.sol';
import { VaultParentManager } from './VaultParentManager.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { VaultOwnershipExternal } from '../vault-ownership/VaultOwnershipExternal.sol';

import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

// Not deployed directly as it's to large only used to generate the ABI and for test interface
contract VaultParent is
    VaultOwnershipExternal,
    VaultParentInvestor,
    VaultParentManager,
    VaultParentTransport,
    VaultBaseExternal
{
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(VaultOwnershipExternal, VaultParentInternal) {
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
    ) internal virtual override(VaultOwnershipExternal, ERC721BaseInternal) {
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
    ) internal virtual override(VaultOwnershipExternal, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}