// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxy.sol - SKALE Interchain Messaging Agent
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

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@skalenetwork/ima-interfaces/IGasReimbursable.sol";
import "@skalenetwork/ima-interfaces/IMessageProxy.sol";
import "@skalenetwork/ima-interfaces/IMessageReceiver.sol";


/**
 * @title MessageProxy
 * @dev Abstract contract for MessageProxyForMainnet and MessageProxyForSchain.
 */
abstract contract MessageProxy is AccessControlEnumerableUpgradeable, IMessageProxy {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Structure that stores counters for outgoing and incoming messages.
     */
    struct ConnectedChainInfo {
        // message counters start with 0
        uint256 incomingMessageCounter;
        uint256 outgoingMessageCounter;
        bool inited;
    }

    bytes32 public constant MAINNET_HASH = keccak256(abi.encodePacked("Mainnet"));
    bytes32 public constant CHAIN_CONNECTOR_ROLE = keccak256("CHAIN_CONNECTOR_ROLE");
    bytes32 public constant EXTRA_CONTRACT_REGISTRAR_ROLE = keccak256("EXTRA_CONTRACT_REGISTRAR_ROLE");
    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");
    uint256 public constant MESSAGES_LENGTH = 10;
    uint256 public constant REVERT_REASON_LENGTH = 64;

    //   schainHash => ConnectedChainInfo
    mapping(bytes32 => ConnectedChainInfo) public connectedChains;
    //   schainHash => contract address => allowed
    // solhint-disable-next-line private-vars-leading-underscore
    mapping(bytes32 => mapping(address => bool)) internal deprecatedRegistryContracts;

    uint256 public gasLimit;

    /**
     * @dev Emitted for every outgoing message to schain.
     */
    event OutgoingMessage(
        bytes32 indexed dstChainHash,
        uint256 indexed msgCounter,
        address indexed srcContract,
        address dstContract,
        bytes data
    );

    /**
     * @dev Emitted when function `postMessage` returns revert.
     *  Used to prevent stuck loop inside function `postIncomingMessages`.
     */
    event PostMessageError(
        uint256 indexed msgCounter,
        bytes message
    );

    /**
     * @dev Emitted when gas limit per one call of `postMessage` was changed.
     */
    event GasLimitWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when the version was updated
     */
    event VersionUpdated(string oldVersion, string newVersion);

    /**
     * @dev Emitted when extra contract was added.
     */
    event ExtraContractRegistered(
        bytes32 indexed chainHash,
        address contractAddress
    );

    /**
     * @dev Emitted when extra contract was removed.
     */
    event ExtraContractRemoved(
        bytes32 indexed chainHash,
        address contractAddress
    );

    /**
     * @dev Modifier to make a function callable only if caller is granted with {CHAIN_CONNECTOR_ROLE}.
     */
    modifier onlyChainConnector() {
        require(hasRole(CHAIN_CONNECTOR_ROLE, msg.sender), "CHAIN_CONNECTOR_ROLE is required");
        _;
    }

    /**
     * @dev Modifier to make a function callable only if caller is granted with {EXTRA_CONTRACT_REGISTRAR_ROLE}.
     */
    modifier onlyExtraContractRegistrar() {
        require(hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender), "EXTRA_CONTRACT_REGISTRAR_ROLE is required");
        _;
    }

    /**
     * @dev Modifier to make a function callable only if caller is granted with {CONSTANT_SETTER_ROLE}.
     */
    modifier onlyConstantSetter() {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "Not enough permissions to set constant");
        _;
    }    

    /**
     * @dev Sets gasLimit to a new value.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CONSTANT_SETTER_ROLE.
     */
    function setNewGasLimit(uint256 newGasLimit) external override onlyConstantSetter {
        emit GasLimitWasChanged(gasLimit, newGasLimit);
        gasLimit = newGasLimit;
    }

    /**
     * @dev Virtual function for `postIncomingMessages`.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    )
        external
        virtual
        override;

    /**
     * @dev Allows `msg.sender` to register extra contract for all schains
     * for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Passed address should be contract.
     * - Extra contract must not be registered.
     */
    function registerExtraContractForAll(address extraContract) external override onlyExtraContractRegistrar {
        require(extraContract.isContract(), "Given address is not a contract");
        require(!_getRegistryContracts()[bytes32(0)].contains(extraContract), "Extra contract is already registered");
        _getRegistryContracts()[bytes32(0)].add(extraContract);
        emit ExtraContractRegistered(bytes32(0), extraContract);
    }

    /**
     * @dev Allows `msg.sender` to remove extra contract for all schains.
     * Extra contract will no longer be able to send messages through MessageProxy.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     */
    function removeExtraContractForAll(address extraContract) external override onlyExtraContractRegistrar {
        require(_getRegistryContracts()[bytes32(0)].contains(extraContract), "Extra contract is not registered");
        _getRegistryContracts()[bytes32(0)].remove(extraContract);
        emit ExtraContractRemoved(bytes32(0), extraContract);
    }

    /**
     * @dev Should return length of contract registered by schainHash.
     */
    function getContractRegisteredLength(bytes32 schainHash) external view override returns (uint256) {
        return _getRegistryContracts()[schainHash].length();
    }

    /**
     * @dev Should return a range of contracts registered by schainHash.
     * 
     * Requirements:
     * range should be less or equal 10 contracts
     */
    function getContractRegisteredRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory contractsInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _getRegistryContracts()[schainHash].length(),
            "Range is incorrect"
        );
        contractsInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            contractsInRange[i - from] = _getRegistryContracts()[schainHash].at(i);
        }
    }

    /**
     * @dev Returns number of outgoing messages.
     * 
     * Requirements:
     * 
     * - Target schain  must be initialized.
     */
    function getOutgoingMessagesCounter(string calldata targetSchainName)
        external
        view
        override
        returns (uint256)
    {
        bytes32 dstChainHash = keccak256(abi.encodePacked(targetSchainName));
        require(connectedChains[dstChainHash].inited, "Destination chain is not initialized");
        return connectedChains[dstChainHash].outgoingMessageCounter;
    }

    /**
     * @dev Returns number of incoming messages.
     * 
     * Requirements:
     * 
     * - Source schain must be initialized.
     */
    function getIncomingMessagesCounter(string calldata fromSchainName)
        external
        view
        override
        returns (uint256)
    {
        bytes32 srcChainHash = keccak256(abi.encodePacked(fromSchainName));
        require(connectedChains[srcChainHash].inited, "Source chain is not initialized");
        return connectedChains[srcChainHash].incomingMessageCounter;
    }

    function initializeMessageProxy(uint newGasLimit) public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CHAIN_CONNECTOR_ROLE, msg.sender);
        _setupRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender);
        _setupRole(CONSTANT_SETTER_ROLE, msg.sender);
        gasLimit = newGasLimit;
    }

    /**
     * @dev Posts message from this contract to `targetChainHash` MessageProxy contract.
     * This is called by a smart contract to make a cross-chain call.
     * 
     * Emits an {OutgoingMessage} event.
     *
     * Requirements:
     * 
     * - Target chain must be initialized.
     * - Target chain must be registered as external contract.
     */
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    )
        public
        override
        virtual
    {
        require(connectedChains[targetChainHash].inited, "Destination chain is not initialized");
        _authorizeOutgoingMessageSender(targetChainHash);
        
        emit OutgoingMessage(
            targetChainHash,
            connectedChains[targetChainHash].outgoingMessageCounter,
            msg.sender,
            targetContract,
            data
        );

        connectedChains[targetChainHash].outgoingMessageCounter += 1;
    }

    /**
     * @dev Allows CHAIN_CONNECTOR_ROLE to remove connected chain from this contract.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CHAIN_CONNECTOR_ROLE.
     * - `schainName` must be initialized.
     */
    function removeConnectedChain(string memory schainName) public virtual override onlyChainConnector {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(connectedChains[schainHash].inited, "Chain is not initialized");
        delete connectedChains[schainHash];
    }    

    /**
     * @dev Checks whether chain is currently connected.
     */
    function isConnectedChain(
        string memory schainName
    )
        public
        view
        virtual
        override
        returns (bool)
    {
        return connectedChains[keccak256(abi.encodePacked(schainName))].inited;
    }

    /**
     * @dev Checks whether contract is currently registered as extra contract.
     */
    function isContractRegistered(
        bytes32 schainHash,
        address contractAddress
    )
        public
        view
        override
        returns (bool)
    {
        return _getRegistryContracts()[schainHash].contains(contractAddress);
    }

    /**
     * @dev Allows MessageProxy to register extra contract for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - Extra contract address must be contract.
     * - Extra contract must not be registered.
     * - Extra contract must not be registered for all chains.
     */
    function _registerExtraContract(
        bytes32 chainHash,
        address extraContract
    )
        internal
    {      
        require(extraContract.isContract(), "Given address is not a contract");
        require(!_getRegistryContracts()[chainHash].contains(extraContract), "Extra contract is already registered");
        require(
            !_getRegistryContracts()[bytes32(0)].contains(extraContract),
            "Extra contract is already registered for all chains"
        );
        
        _getRegistryContracts()[chainHash].add(extraContract);
        emit ExtraContractRegistered(chainHash, extraContract);
    }

    /**
     * @dev Allows MessageProxy to remove extra contract,
     * thus `extraContract` will no longer be available to transfer messages from mainnet to schain.
     * 
     * Requirements:
     * 
     * - Extra contract must be registered.
     */
    function _removeExtraContract(
        bytes32 chainHash,
        address extraContract
    )
        internal
    {
        require(_getRegistryContracts()[chainHash].contains(extraContract), "Extra contract is not registered");
        _getRegistryContracts()[chainHash].remove(extraContract);
        emit ExtraContractRemoved(chainHash, extraContract);
    }

    /**
     * @dev Allows MessageProxy to connect schain with MessageProxyOnMainnet for transferring messages.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CHAIN_CONNECTOR_ROLE.
     * - SKALE chain must not be connected.
     */
    function _addConnectedChain(bytes32 schainHash) internal onlyChainConnector {
        require(!connectedChains[schainHash].inited,"Chain is already connected");
        connectedChains[schainHash] = ConnectedChainInfo({
            incomingMessageCounter: 0,
            outgoingMessageCounter: 0,
            inited: true
        });
    }

    /**
     * @dev Allows MessageProxy to send messages from schain to mainnet.
     * Destination contract must implement `postMessage` method.
     */
    function _callReceiverContract(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        internal
    {
        if (!message.destinationContract.isContract()) {
            emit PostMessageError(
                counter,
                "Destination contract is not a contract"
            );
            return;
        }
        try IMessageReceiver(message.destinationContract).postMessage{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) {
            return;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                _getSlice(bytes(reason), REVERT_REASON_LENGTH)
            );
        } catch Panic(uint errorCode) {
               emit PostMessageError(
                counter,
                abi.encodePacked(errorCode)
            );
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                _getSlice(revertData, REVERT_REASON_LENGTH)
            );
        }
    }

    /**
     * @dev Returns receiver of message.
     */
    function _getGasPayer(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        internal
        returns (address)
    {
        try IGasReimbursable(message.destinationContract).gasPayer{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) returns (address receiver) {
            return receiver;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                _getSlice(bytes(reason), REVERT_REASON_LENGTH)
            );
            return address(0);
        } catch Panic(uint errorCode) {
               emit PostMessageError(
                counter,
                abi.encodePacked(errorCode)
            );
            return address(0);
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                _getSlice(revertData, REVERT_REASON_LENGTH)
            );
            return address(0);
        }
    }

    /**
     * @dev Checks whether msg.sender is registered as custom extra contract.
     */
    function _authorizeOutgoingMessageSender(bytes32 targetChainHash) internal view virtual {
        require(
            isContractRegistered(bytes32(0), msg.sender) || isContractRegistered(targetChainHash, msg.sender),
            "Sender contract is not registered"
        );        
    }

    /**
     * @dev Returns list of registered custom extra contracts.
     */
    function _getRegistryContracts()
        internal
        view
        virtual
        returns (mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) storage);

    /**
     * @dev Returns hash of message array.
     */
    function _hashedArray(
        Message[] calldata messages,
        uint256 startingCounter,
        string calldata fromChainName
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32 sourceHash = keccak256(abi.encodePacked(fromChainName));
        bytes32 hash = keccak256(abi.encodePacked(sourceHash, bytes32(startingCounter)));
        for (uint256 i = 0; i < messages.length; i++) {
            hash = keccak256(
                abi.encodePacked(
                    abi.encode(
                        hash,
                        messages[i].sender,
                        messages[i].destinationContract
                    ),
                    messages[i].data
                )
            );
        }
        return hash;
    }

    function _getSlice(bytes memory text, uint end) private pure returns (bytes memory) {
        uint slicedEnd = end < text.length ? end : text.length;
        bytes memory sliced = new bytes(slicedEnd);
        for(uint i = 0; i < slicedEnd; i++){
            sliced[i] = text[i];
        }
        return sliced;    
    }
}