// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBoxERC1155.sol - SKALE Interchain Messaging Agent
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

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@skalenetwork/ima-interfaces/mainnet/DepositBoxes/IDepositBoxERC1155.sol";

import "../DepositBox.sol";
import "../../Messages.sol";


/**
 * @title DepositBoxERC1155
 * @dev Runs on mainnet,
 * accepts messages from schain,
 * stores deposits of ERC1155.
 */
contract DepositBoxERC1155 is DepositBox, ERC1155ReceiverUpgradeable, IDepositBoxERC1155 {

    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;


    // schainHash => address of ERC on Mainnet
    // Deprecated
    // slither-disable-next-line unused-state
    mapping(bytes32 => mapping(address => bool)) private _deprecatedSchainToERC1155;
    mapping(bytes32 => mapping(address => mapping(uint256 => uint256))) public transferredAmount;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _schainToERC1155;

    /**
     * @dev Emitted when token is mapped in DepositBoxERC20.
     */
    event ERC1155TokenAdded(string schainName, address indexed contractOnMainnet);

    /**
     * @dev Emitted when token is received by DepositBox and is ready to be cloned
     * or transferred on SKALE chain.
     */
    event ERC1155TokenReady(address indexed contractOnMainnet, uint256[] ids, uint256[] amounts);

    /**
     * @dev Allows `msg.sender` to send ERC1155 token from mainnet to schain.
     * 
     * Requirements:
     * 
     * - Receiver contract should be defined.
     * - `msg.sender` should approve their tokens for DepositBoxERC1155 address.
     */
    function depositERC1155(
        string calldata schainName,
        address erc1155OnMainnet,
        uint256 id,
        uint256 amount
    )
        external
        override
        rightTransaction(schainName, msg.sender)
        whenNotKilled(keccak256(abi.encodePacked(schainName)))
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        address contractReceiver = schainLinks[schainHash];
        require(contractReceiver != address(0), "Unconnected chain");
        require(
            IERC1155Upgradeable(erc1155OnMainnet).isApprovedForAll(msg.sender, address(this)),
            "DepositBox was not approved for ERC1155 token"
        );
        bytes memory data = _receiveERC1155(
            schainName,
            erc1155OnMainnet,
            msg.sender,
            id,
            amount
        );
        _saveTransferredAmount(schainHash, erc1155OnMainnet, _asSingletonArray(id), _asSingletonArray(amount));
        IERC1155Upgradeable(erc1155OnMainnet).safeTransferFrom(msg.sender, address(this), id, amount, "");
        messageProxy.postOutgoingMessage(
            schainHash,
            contractReceiver,
            data
        );
    }

    /**
     * @dev Allows `msg.sender` to send batch of ERC1155 tokens from mainnet to schain.
     * 
     * Requirements:
     * 
     * - Receiver contract should be defined.
     * - `msg.sender` should approve their tokens for DepositBoxERC1155 address.
     */
    function depositERC1155Batch(
        string calldata schainName,
        address erc1155OnMainnet,
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        external
        override
        rightTransaction(schainName, msg.sender)
        whenNotKilled(keccak256(abi.encodePacked(schainName)))
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        address contractReceiver = schainLinks[schainHash];
        require(contractReceiver != address(0), "Unconnected chain");
        require(
            IERC1155Upgradeable(erc1155OnMainnet).isApprovedForAll(msg.sender, address(this)),
            "DepositBox was not approved for ERC1155 token Batch"
        );
        bytes memory data = _receiveERC1155Batch(
            schainName,
            erc1155OnMainnet,
            msg.sender,
            ids,
            amounts
        );
        _saveTransferredAmount(schainHash, erc1155OnMainnet, ids, amounts);
        IERC1155Upgradeable(erc1155OnMainnet).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        messageProxy.postOutgoingMessage(
            schainHash,
            contractReceiver,
            data
        );
    }

    /**
     * @dev Allows MessageProxyForMainnet contract to execute transferring ERC1155 token from schain to mainnet.
     * 
     * Requirements:
     * 
     * - Schain from which the tokens came should not be killed.
     * - Sender contract should be added to DepositBoxERC1155 and schain name cannot be `Mainnet`.
     * - Amount of tokens on DepositBoxERC1155 should be equal or more than transferred amount.
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
        Messages.MessageType operation = Messages.getMessageType(data);
        if (operation == Messages.MessageType.TRANSFER_ERC1155) {
            Messages.TransferErc1155Message memory message = Messages.decodeTransferErc1155Message(data);
            require(message.token.isContract(), "Given address is not a contract");
            _removeTransferredAmount(
                schainHash,
                message.token,
                _asSingletonArray(message.id),
                _asSingletonArray(message.amount)
            );
            IERC1155Upgradeable(message.token).safeTransferFrom(
                address(this),
                message.receiver,
                message.id,
                message.amount,
                ""
            );
        } else if (operation == Messages.MessageType.TRANSFER_ERC1155_BATCH) {
            Messages.TransferErc1155BatchMessage memory message = Messages.decodeTransferErc1155BatchMessage(data);
            require(message.token.isContract(), "Given address is not a contract");
            _removeTransferredAmount(schainHash, message.token, message.ids, message.amounts);
            IERC1155Upgradeable(message.token).safeBatchTransferFrom(
                address(this),
                message.receiver,
                message.ids,
                message.amounts,
                ""
            );
        }
    }

    /**
     * @dev Allows Schain owner to add an ERC1155 token to DepositBoxERC1155.
     * 
     * Emits an {ERC1155TokenAdded} event.
     * 
     * Requirements:
     * 
     * - Schain should not be killed.
     * - Only owner of the schain able to run function.
     */
    function addERC1155TokenByOwner(
        string calldata schainName,
        address erc1155OnMainnet
    )
        external
        override
        onlySchainOwner(schainName)
        whenNotKilled(keccak256(abi.encodePacked(schainName)))
    {
        _addERC1155ForSchain(schainName, erc1155OnMainnet);
    }

    /**
     * @dev Allows Schain owner to return each user their tokens.
     * The Schain owner decides which tokens to send to which address, 
     * since the contract on mainnet does not store information about which tokens belong to whom.
     *
     * Requirements:
     * 
     * - Amount of tokens on schain should be equal or more than transferred amount.
     * - msg.sender should be an owner of schain
     * - IMA transfers Mainnet <-> schain should be killed
     */
    function getFunds(
        string calldata schainName,
        address erc1155OnMainnet,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
        override
        onlySchainOwner(schainName)
        whenKilled(keccak256(abi.encodePacked(schainName)))
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(ids.length == amounts.length, "Incorrect length of arrays");
        for (uint256 i = 0; i < ids.length; i++) {
            require(transferredAmount[schainHash][erc1155OnMainnet][ids[i]] >= amounts[i], "Incorrect amount");
        }
        _removeTransferredAmount(schainHash, erc1155OnMainnet, ids, amounts);
        IERC1155Upgradeable(erc1155OnMainnet).safeBatchTransferFrom(
            address(this),
            receiver,
            ids,
            amounts,
            ""
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
        Messages.MessageType operation = Messages.getMessageType(data);
        if (operation == Messages.MessageType.TRANSFER_ERC1155) {
            Messages.TransferErc1155Message memory message = Messages.decodeTransferErc1155Message(data);
            return message.receiver;
        } else if (operation == Messages.MessageType.TRANSFER_ERC1155_BATCH) {
            Messages.TransferErc1155BatchMessage memory message = Messages.decodeTransferErc1155BatchMessage(data);
            return message.receiver;
        }
        return address(0);
    }


    /**
     * @dev Returns selector of onERC1155Received.
     */
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        view
        override
        returns(bytes4)
    {
        require(operator == address(this), "Revert ERC1155 transfer");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }


    /**
     * @dev Returns selector of onERC1155BatchReceived.
     */
    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        view
        override
        returns(bytes4)
    {
        require(operator == address(this), "Revert ERC1155 batch transfer");
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /**
     * @dev Should return true if token was added by Schain owner or 
     * added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToERC1155(
        string calldata schainName,
        address erc1155OnMainnet
    )
        external
        view
        override
        returns (bool)
    {
        return _schainToERC1155[keccak256(abi.encodePacked(schainName))].contains(erc1155OnMainnet);
    }

    /**
     * @dev Should return length of a set of all mapped tokens which were added by Schain owner 
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC1155Length(string calldata schainName) external view override returns (uint256) {
        return _schainToERC1155[keccak256(abi.encodePacked(schainName))].length();
    }

    /**
     * @dev Should return an array of tokens were added by Schain owner or 
     * added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC1155(
        string calldata schainName,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory tokensInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _schainToERC1155[keccak256(abi.encodePacked(schainName))].length(),
            "Range is incorrect"
        );
        tokensInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            tokensInRange[i - from] = _schainToERC1155[keccak256(abi.encodePacked(schainName))].at(i);
        }
    }

    /**
     * @dev Creates a new DepositBoxERC1155 contract.
     */
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,        
        ILinker linkerValue,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override(DepositBox, IDepositBox)
        initializer
    {
        DepositBox.initialize(contractManagerOfSkaleManagerValue, linkerValue, messageProxyValue);
        __ERC1155Receiver_init();
    }

    /**
     * @dev Checks whether contract supports such interface (first 4 bytes of method name and its params).
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlEnumerableUpgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return interfaceId == type(Twin).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Saves amount of tokens that was transferred to schain.
     */
    function _saveTransferredAmount(
        bytes32 schainHash,
        address erc1155Token,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        require(ids.length == amounts.length, "Incorrect length of arrays");
        for (uint256 i = 0; i < ids.length; i++)
            transferredAmount[schainHash][erc1155Token][ids[i]] =
                transferredAmount[schainHash][erc1155Token][ids[i]] + amounts[i];
    }

    /**
     * @dev Removes amount of tokens that was transferred from schain.
     */
    function _removeTransferredAmount(
        bytes32 schainHash,
        address erc1155Token,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        require(ids.length == amounts.length, "Incorrect length of arrays");
        for (uint256 i = 0; i < ids.length; i++)
            transferredAmount[schainHash][erc1155Token][ids[i]] =
                transferredAmount[schainHash][erc1155Token][ids[i]] - amounts[i];
    }

    /**
     * @dev Allows DepositBoxERC1155 to receive ERC1155 tokens.
     * 
     * Emits an {ERC1155TokenReady} event.
     * 
     * Requirements:
     * 
     * - Whitelist should be turned off for auto adding tokens to DepositBoxERC1155.
     */
    function _receiveERC1155(
        string calldata schainName,
        address erc1155OnMainnet,
        address to,
        uint256 id,
        uint256 amount
    )
        private
        returns (bytes memory data)
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        bool isERC1155AddedToSchain = _schainToERC1155[schainHash].contains(erc1155OnMainnet);
        if (!isERC1155AddedToSchain) {
            require(!isWhitelisted(schainName), "Whitelist is enabled");
            _addERC1155ForSchain(schainName, erc1155OnMainnet);
            data = Messages.encodeTransferErc1155AndTokenInfoMessage(
                erc1155OnMainnet,
                to,
                id,
                amount,
                _getTokenInfo(IERC1155MetadataURIUpgradeable(erc1155OnMainnet))
            );
        } else {
            data = Messages.encodeTransferErc1155Message(erc1155OnMainnet, to, id, amount);
        }
        
        emit ERC1155TokenReady(erc1155OnMainnet, _asSingletonArray(id), _asSingletonArray(amount));
    }

    /**
     * @dev Allows DepositBoxERC1155 to receive ERC1155 tokens.
     * 
     * Emits an {ERC1155TokenReady} event.
     * 
     * Requirements:
     * 
     * - Whitelist should be turned off for auto adding tokens to DepositBoxERC1155.
     */
    function _receiveERC1155Batch(
        string calldata schainName,
        address erc1155OnMainnet,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        private
        returns (bytes memory data)
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        bool isERC1155AddedToSchain = _schainToERC1155[schainHash].contains(erc1155OnMainnet);
        if (!isERC1155AddedToSchain) {
            require(!isWhitelisted(schainName), "Whitelist is enabled");
            _addERC1155ForSchain(schainName, erc1155OnMainnet);
            data = Messages.encodeTransferErc1155BatchAndTokenInfoMessage(
                erc1155OnMainnet,
                to,
                ids,
                amounts,
                _getTokenInfo(IERC1155MetadataURIUpgradeable(erc1155OnMainnet))
            );
        } else {
            data = Messages.encodeTransferErc1155BatchMessage(erc1155OnMainnet, to, ids, amounts);
        }
        emit ERC1155TokenReady(erc1155OnMainnet, ids, amounts);
    }

    /**
     * @dev Adds an ERC1155 token to DepositBoxERC1155.
     * 
     * Emits an {ERC1155TokenAdded} event.
     * 
     * Requirements:
     * 
     * - Given address should be contract.
     */
    function _addERC1155ForSchain(string calldata schainName, address erc1155OnMainnet) private {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(erc1155OnMainnet.isContract(), "Given address is not a contract");
        require(!_schainToERC1155[schainHash].contains(erc1155OnMainnet), "ERC1155 Token was already added");
        _schainToERC1155[schainHash].add(erc1155OnMainnet);
        emit ERC1155TokenAdded(schainName, erc1155OnMainnet);
    }

    /**
     * @dev Returns info about ERC1155 token.
     */
    function _getTokenInfo(
        IERC1155MetadataURIUpgradeable erc1155
    )
        private
        view
        returns (Messages.Erc1155TokenInfo memory)
    {
        return Messages.Erc1155TokenInfo({uri: erc1155.uri(0)});
    }

    /**
     * @dev Returns array with single element that passed as argument.
     */
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }
}