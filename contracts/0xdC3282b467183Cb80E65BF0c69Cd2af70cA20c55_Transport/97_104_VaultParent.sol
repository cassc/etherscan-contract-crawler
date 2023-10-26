// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultParentTransport } from './VaultParentTransport.sol';
import { VaultParentInvestor } from './VaultParentInvestor.sol';
import { VaultParentManager } from './VaultParentManager.sol';
import { VaultParentErc721 } from './VaultParentErc721.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { IRedeemerEvents } from '../redeemers/IRedeemerEvents.sol';
import { IExecutorEvents } from '../executors/IExecutorEvents.sol';

import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { ERC721BaseInternal, ERC165Base } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

// Not deployed directly as It's to large
// ONLY used to generate the ABI and for test interface
contract VaultParent is
    VaultParentInvestor,
    VaultParentErc721,
    VaultParentManager,
    VaultParentTransport,
    VaultBaseExternal,
    IRedeemerEvents,
    IExecutorEvents
{
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(VaultParentErc721, VaultParentInternal) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(VaultParentErc721, ERC721BaseInternal) {
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
    ) internal virtual override(VaultParentErc721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}