// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Messages.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
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


/**
 * @title Messages
 * @dev Library for encoding and decoding messages
 * for transferring from Mainnet to Schain and vice versa.
 */
library Messages {

    /**
     * @dev Enumerator that describes all supported message types.
     */
    enum MessageType {
        EMPTY,
        TRANSFER_ETH,
        TRANSFER_ERC20,
        TRANSFER_ERC20_AND_TOTAL_SUPPLY,
        TRANSFER_ERC20_AND_TOKEN_INFO,
        TRANSFER_ERC721,
        TRANSFER_ERC721_AND_TOKEN_INFO,
        USER_STATUS,
        INTERCHAIN_CONNECTION,
        TRANSFER_ERC1155,
        TRANSFER_ERC1155_AND_TOKEN_INFO,
        TRANSFER_ERC1155_BATCH,
        TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO,
        TRANSFER_ERC721_WITH_METADATA,
        TRANSFER_ERC721_WITH_METADATA_AND_TOKEN_INFO
    }

    /**
     * @dev Structure for base message.
     */
    struct BaseMessage {
        MessageType messageType;
    }

    /**
     * @dev Structure for describing ETH.
     */
    struct TransferEthMessage {
        BaseMessage message;
        address receiver;
        uint256 amount;
    }

    /**
     * @dev Structure for user status.
     */
    struct UserStatusMessage {
        BaseMessage message;
        address receiver;
        bool isActive;
    }

    /**
     * @dev Structure for describing ERC20 token.
     */
    struct TransferErc20Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 amount;
    }

    /**
     * @dev Structure for describing additional data for ERC20 token.
     */
    struct Erc20TokenInfo {
        string name;
        uint8 decimals;
        string symbol;
    }

    /**
     * @dev Structure for describing ERC20 with token supply.
     */
    struct TransferErc20AndTotalSupplyMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
    }

    /**
     * @dev Structure for describing ERC20 with token info.
     */
    struct TransferErc20AndTokenInfoMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
        Erc20TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing base ERC721.
     */
    struct TransferErc721Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 tokenId;
    }

    /**
     * @dev Structure for describing base ERC721 with metadata.
     */
    struct TransferErc721MessageWithMetadata {
        TransferErc721Message erc721message;
        string tokenURI;
    }

    /**
     * @dev Structure for describing ERC20 with token info.
     */
    struct Erc721TokenInfo {
        string name;
        string symbol;
    }

    /**
     * @dev Structure for describing additional data for ERC721 token.
     */
    struct TransferErc721AndTokenInfoMessage {
        TransferErc721Message baseErc721transfer;
        Erc721TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing additional data for ERC721 token with metadata.
     */
    struct TransferErc721WithMetadataAndTokenInfoMessage {
        TransferErc721MessageWithMetadata baseErc721transferWithMetadata;
        Erc721TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing whether interchain connection is allowed.
     */
    struct InterchainConnectionMessage {
        BaseMessage message;
        bool isAllowed;
    }

    /**
     * @dev Structure for describing whether interchain connection is allowed.
     */
    struct TransferErc1155Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 id;
        uint256 amount;
    }

    /**
     * @dev Structure for describing ERC1155 token in batches.
     */
    struct TransferErc1155BatchMessage {
        BaseMessage message;
        address token;
        address receiver;
        uint256[] ids;
        uint256[] amounts;
    }

    /**
     * @dev Structure for describing ERC1155 token info.
     */
    struct Erc1155TokenInfo {
        string uri;
    }

    /**
     * @dev Structure for describing message for transferring ERC1155 token with info.
     */
    struct TransferErc1155AndTokenInfoMessage {
        TransferErc1155Message baseErc1155transfer;
        Erc1155TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing message for transferring ERC1155 token in batches with info.
     */
    struct TransferErc1155BatchAndTokenInfoMessage {
        TransferErc1155BatchMessage baseErc1155Batchtransfer;
        Erc1155TokenInfo tokenInfo;
    }


    /**
     * @dev Returns type of message for encoded data.
     */
    function getMessageType(bytes calldata data) internal pure returns (MessageType) {
        uint256 firstWord = abi.decode(data, (uint256));
        if (firstWord % 32 == 0) {
            return getMessageType(data[firstWord:]);
        } else {
            return abi.decode(data, (Messages.MessageType));
        }
    }

    /**
     * @dev Encodes message for transferring ETH. Returns encoded message.
     */
    function encodeTransferEthMessage(address receiver, uint256 amount) internal pure returns (bytes memory) {
        TransferEthMessage memory message = TransferEthMessage(
            BaseMessage(MessageType.TRANSFER_ETH),
            receiver,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ETH. Returns structure `TransferEthMessage`.
     */
    function decodeTransferEthMessage(
        bytes calldata data
    ) internal pure returns (TransferEthMessage memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ETH, "Message type is not ETH transfer");
        return abi.decode(data, (TransferEthMessage));
    }

    /**
     * @dev Encodes message for transferring ETH. Returns encoded message.
     */
    function encodeTransferErc20Message(
        address token,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc20Message memory message = TransferErc20Message(
            BaseMessage(MessageType.TRANSFER_ERC20),
            token,
            receiver,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Encodes message for transferring ERC20 with total supply. Returns encoded message.
     */
    function encodeTransferErc20AndTotalSupplyMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply
    ) internal pure returns (bytes memory) {
        TransferErc20AndTotalSupplyMessage memory message = TransferErc20AndTotalSupplyMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY),
                token,
                receiver,
                amount
            ),
            totalSupply
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC20. Returns structure `TransferErc20Message`.
     */
    function decodeTransferErc20Message(
        bytes calldata data
    ) internal pure returns (TransferErc20Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC20, "Message type is not ERC20 transfer");
        return abi.decode(data, (TransferErc20Message));
    }

    /**
     * @dev Decodes message for transferring ERC20 with total supply. 
     * Returns structure `TransferErc20AndTotalSupplyMessage`.
     */
    function decodeTransferErc20AndTotalSupplyMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTotalSupplyMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY,
            "Message type is not ERC20 transfer and total supply"
        );
        return abi.decode(data, (TransferErc20AndTotalSupplyMessage));
    }

    /**
     * @dev Encodes message for transferring ERC20 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc20AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply,
        Erc20TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc20AndTokenInfoMessage memory message = TransferErc20AndTokenInfoMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOKEN_INFO),
                token,
                receiver,
                amount
            ),
            totalSupply,
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC20 with token info. 
     * Returns structure `TransferErc20AndTokenInfoMessage`.
     */
    function decodeTransferErc20AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOKEN_INFO,
            "Message type is not ERC20 transfer with token info"
        );
        return abi.decode(data, (TransferErc20AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC721. 
     * Returns encoded message.
     */
    function encodeTransferErc721Message(
        address token,
        address receiver,
        uint256 tokenId
    ) internal pure returns (bytes memory) {
        TransferErc721Message memory message = TransferErc721Message(
            BaseMessage(MessageType.TRANSFER_ERC721),
            token,
            receiver,
            tokenId
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721. 
     * Returns structure `TransferErc721Message`.
     */
    function decodeTransferErc721Message(
        bytes calldata data
    ) internal pure returns (TransferErc721Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC721, "Message type is not ERC721 transfer");
        return abi.decode(data, (TransferErc721Message));
    }

    /**
     * @dev Encodes message for transferring ERC721 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc721AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 tokenId,
        Erc721TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc721AndTokenInfoMessage memory message = TransferErc721AndTokenInfoMessage(
            TransferErc721Message(
                BaseMessage(MessageType.TRANSFER_ERC721_AND_TOKEN_INFO),
                token,
                receiver,
                tokenId
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721 with token info. 
     * Returns structure `TransferErc721AndTokenInfoMessage`.
     */
    function decodeTransferErc721AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc721AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_AND_TOKEN_INFO,
            "Message type is not ERC721 transfer with token info"
        );
        return abi.decode(data, (TransferErc721AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC721. 
     * Returns encoded message.
     */
    function encodeTransferErc721MessageWithMetadata(
        address token,
        address receiver,
        uint256 tokenId,
        string memory tokenURI
    ) internal pure returns (bytes memory) {
        TransferErc721MessageWithMetadata memory message = TransferErc721MessageWithMetadata(
            TransferErc721Message(
                BaseMessage(MessageType.TRANSFER_ERC721_WITH_METADATA),
                token,
                receiver,
                tokenId
            ),
            tokenURI
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721. 
     * Returns structure `TransferErc721MessageWithMetadata`.
     */
    function decodeTransferErc721MessageWithMetadata(
        bytes calldata data
    ) internal pure returns (TransferErc721MessageWithMetadata memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_WITH_METADATA,
            "Message type is not ERC721 transfer"
        );
        return abi.decode(data, (TransferErc721MessageWithMetadata));
    }

    /**
     * @dev Encodes message for transferring ERC721 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc721WithMetadataAndTokenInfoMessage(
        address token,
        address receiver,
        uint256 tokenId,
        string memory tokenURI,
        Erc721TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc721WithMetadataAndTokenInfoMessage memory message = TransferErc721WithMetadataAndTokenInfoMessage(
            TransferErc721MessageWithMetadata(
                TransferErc721Message(
                    BaseMessage(MessageType.TRANSFER_ERC721_WITH_METADATA_AND_TOKEN_INFO),
                    token,
                    receiver,
                    tokenId
                ),
                tokenURI
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721 with token info. 
     * Returns structure `TransferErc721WithMetadataAndTokenInfoMessage`.
     */
    function decodeTransferErc721WithMetadataAndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc721WithMetadataAndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_WITH_METADATA_AND_TOKEN_INFO,
            "Message type is not ERC721 transfer with token info"
        );
        return abi.decode(data, (TransferErc721WithMetadataAndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for activating user on schain. 
     * Returns encoded message.
     */
    function encodeActivateUserMessage(address receiver) internal pure returns (bytes memory){
        return _encodeUserStatusMessage(receiver, true);
    }

    /**
     * @dev Encodes message for locking user on schain. 
     * Returns encoded message.
     */
    function encodeLockUserMessage(address receiver) internal pure returns (bytes memory){
        return _encodeUserStatusMessage(receiver, false);
    }

    /**
     * @dev Decodes message for user status. 
     * Returns structure UserStatusMessage.
     */
    function decodeUserStatusMessage(bytes calldata data) internal pure returns (UserStatusMessage memory) {
        require(getMessageType(data) == MessageType.USER_STATUS, "Message type is not User Status");
        return abi.decode(data, (UserStatusMessage));
    }


    /**
     * @dev Encodes message for allowing interchain connection.
     * Returns encoded message.
     */
    function encodeInterchainConnectionMessage(bool isAllowed) internal pure returns (bytes memory) {
        InterchainConnectionMessage memory message = InterchainConnectionMessage(
            BaseMessage(MessageType.INTERCHAIN_CONNECTION),
            isAllowed
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for allowing interchain connection.
     * Returns structure `InterchainConnectionMessage`.
     */
    function decodeInterchainConnectionMessage(bytes calldata data)
        internal
        pure
        returns (InterchainConnectionMessage memory)
    {
        require(getMessageType(data) == MessageType.INTERCHAIN_CONNECTION, "Message type is not Interchain connection");
        return abi.decode(data, (InterchainConnectionMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token.
     * Returns encoded message.
     */
    function encodeTransferErc1155Message(
        address token,
        address receiver,
        uint256 id,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc1155Message memory message = TransferErc1155Message(
            BaseMessage(MessageType.TRANSFER_ERC1155),
            token,
            receiver,
            id,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token.
     * Returns structure `TransferErc1155Message`.
     */
    function decodeTransferErc1155Message(
        bytes calldata data
    ) internal pure returns (TransferErc1155Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC1155, "Message type is not ERC1155 transfer");
        return abi.decode(data, (TransferErc1155Message));
    }

    /**
     * @dev Encodes message for transferring ERC1155 with token info.
     * Returns encoded message.
     */
    function encodeTransferErc1155AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 id,
        uint256 amount,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155AndTokenInfoMessage memory message = TransferErc1155AndTokenInfoMessage(
            TransferErc1155Message(
                BaseMessage(MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO),
                token,
                receiver,
                id,
                amount
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 with token info.
     * Returns structure `TransferErc1155AndTokenInfoMessage`.
     */
    function decodeTransferErc1155AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO,
            "Message type is not ERC1155AndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token in batches.
     * Returns encoded message.
     */
    function encodeTransferErc1155BatchMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchMessage memory message = TransferErc1155BatchMessage(
            BaseMessage(MessageType.TRANSFER_ERC1155_BATCH),
            token,
            receiver,
            ids,
            amounts
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token in batches.
     * Returns structure `TransferErc1155BatchMessage`.
     */
    function decodeTransferErc1155BatchMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH,
            "Message type is not ERC1155Batch transfer"
        );
        return abi.decode(data, (TransferErc1155BatchMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token in batches with token info.
     * Returns encoded message.
     */
    function encodeTransferErc1155BatchAndTokenInfoMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchAndTokenInfoMessage memory message = TransferErc1155BatchAndTokenInfoMessage(
            TransferErc1155BatchMessage(
                BaseMessage(MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO),
                token,
                receiver,
                ids,
                amounts
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token in batches with token info.
     * Returns structure `TransferErc1155BatchAndTokenInfoMessage`.
     */
    function decodeTransferErc1155BatchAndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchAndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO,
            "Message type is not ERC1155BatchAndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155BatchAndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring user status on schain.
     * Returns encoded message.
     */
    function _encodeUserStatusMessage(address receiver, bool isActive) private pure returns (bytes memory) {
        UserStatusMessage memory message = UserStatusMessage(
            BaseMessage(MessageType.USER_STATUS),
            receiver,
            isActive
        );
        return abi.encode(message);
    }

}