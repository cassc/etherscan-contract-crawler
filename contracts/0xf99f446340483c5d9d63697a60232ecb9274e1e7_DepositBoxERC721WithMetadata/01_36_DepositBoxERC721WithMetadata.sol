// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBoxERC721WithMetadata.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./DepositBoxERC721.sol";
import "../../Messages.sol";

/**
 * @title DepositBoxERC721WithMetadata
 * @dev Runs on mainnet,
 * accepts messages from schain,
 * stores deposits of ERC721.
 */
contract DepositBoxERC721WithMetadata is DepositBoxERC721 {
    using AddressUpgradeable for address;

    /**
     * @dev Allows MessageProxyForMainnet contract to execute transferring ERC721 token from schain to mainnet.
     * 
     * Requirements:
     * 
     * - Schain from which the tokens came should not be killed.
     * - Sender contract should be defined and schain name cannot be `Mainnet`.
     * - DepositBoxERC721 contract should own token.
     */
    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        override
        onlyMessageProxy
        whenNotKilled(schainHash)
        checkReceiverChain(schainHash, sender)
    {
        Messages.TransferErc721MessageWithMetadata memory message =
            Messages.decodeTransferErc721MessageWithMetadata(data);
        require(message.erc721message.token.isContract(), "Given address is not a contract");
        require(
            IERC721Upgradeable(message.erc721message.token).ownerOf(message.erc721message.tokenId) == address(this),
            "Incorrect tokenId"
        );
        _removeTransferredAmount(message.erc721message.token, message.erc721message.tokenId);
        IERC721Upgradeable(message.erc721message.token).transferFrom(
            address(this),
            message.erc721message.receiver,
            message.erc721message.tokenId
        );
    }

    /**
     * @dev Returns receiver of message.
     *
     * Requirements:
     *
     * - Sender contract should be defined and schain name cannot be `Mainnet`.
     */
    function gasPayer(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        view
        override
        checkReceiverChain(schainHash, sender)
        returns (address)
    {
        Messages.TransferErc721MessageWithMetadata memory message =
            Messages.decodeTransferErc721MessageWithMetadata(data);
        return message.erc721message.receiver;
    }

    /**
     * @dev Allows DepositBoxERC721 to receive ERC721 tokens.
     * 
     * Emits an {ERC721TokenReady} event.
     * 
     * Requirements:
     * 
     * - Whitelist should be turned off for auto adding tokens to DepositBoxERC721.
     */
    function _receiveERC721(
        string calldata schainName,
        address erc721OnMainnet,
        address to,
        uint256 tokenId
    )
        internal
        override
        returns (bytes memory data)
    {
        bool isERC721AddedToSchain = getSchainToERC721(schainName, erc721OnMainnet);
        if (!isERC721AddedToSchain) {
            require(!isWhitelisted(schainName), "Whitelist is enabled");
            _addERC721ForSchain(schainName, erc721OnMainnet);
            data = Messages.encodeTransferErc721WithMetadataAndTokenInfoMessage(
                erc721OnMainnet,
                to,
                tokenId,
                _getTokenURI(IERC721MetadataUpgradeable(erc721OnMainnet), tokenId),
                _getTokenInfo(IERC721MetadataUpgradeable(erc721OnMainnet))
            );
        } else {
            data = Messages.encodeTransferErc721MessageWithMetadata(
                erc721OnMainnet,
                to,
                tokenId,
                _getTokenURI(IERC721MetadataUpgradeable(erc721OnMainnet), tokenId)
            );
        }
        emit ERC721TokenReady(erc721OnMainnet, tokenId);
    }

    /**
     * @dev Returns tokenURI of ERC721 token.
     */
    function _getTokenURI(IERC721MetadataUpgradeable erc721, uint256 tokenId) private view returns (string memory) {
        return erc721.tokenURI(tokenId);
    }

}