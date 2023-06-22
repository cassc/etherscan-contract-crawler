// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxyForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
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
import "@skalenetwork/skale-manager-interfaces/IWallets.sol";
import "@skalenetwork/skale-manager-interfaces/ISchains.sol";
import "@skalenetwork/ima-interfaces/mainnet/IMessageProxyForMainnet.sol";
import "@skalenetwork/ima-interfaces/mainnet/ICommunityPool.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";


import "../MessageProxy.sol";
import "./SkaleManagerClient.sol";
import "./CommunityPool.sol";


/**
 * @title Message Proxy for Mainnet
 * @dev Runs on Mainnet, contains functions to manage the incoming messages from
 * `targetSchainName` and outgoing messages to `fromSchainName`. Every SKALE chain with
 * IMA is therefore connected to MessageProxyForMainnet.
 *
 * Messages from SKALE chains are signed using BLS threshold signatures from the
 * nodes in the chain. Since Ethereum Mainnet has no BLS public key, mainnet
 * messages do not need to be signed.
 */
contract MessageProxyForMainnet is SkaleManagerClient, MessageProxy, IMessageProxyForMainnet {

    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Pause {
        bool paused;
    }

    bytes32 public constant PAUSABLE_ROLE = keccak256(abi.encodePacked("PAUSABLE_ROLE"));

    /**
     * 16 Agents
     * Synchronize time with time.nist.gov
     * Every agent checks if it is their time slot
     * Time slots are in increments of 10 seconds
     * At the start of their slot each agent:
     * For each connected schain:
     * Read incoming counter on the dst chain
     * Read outgoing counter on the src chain
     * Calculate the difference outgoing - incoming
     * Call postIncomingMessages function passing (un)signed message array
     * ID of this schain, Chain 0 represents ETH mainnet,
    */

    ICommunityPool public communityPool;

    uint256 public headerMessageGasCost;
    uint256 public messageGasCost;

    // disable detector until slither will fix this issue
    // https://github.com/crytic/slither/issues/456
    // slither-disable-next-line uninitialized-state
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _registryContracts;
    string public version;
    bool public override messageInProgress;

    // schainHash   => Pause structure
    mapping(bytes32 => Pause) public pauseInfo;

    //   schainHash => Set of addresses of reimbursed contracts
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _reimbursedContracts;

    /**
     * @dev Emitted when gas cost for message header was changed.
     */
    event GasCostMessageHeaderWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when gas cost for message was changed.
     */
    event GasCostMessageWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when the schain is paused
     */
    event SchainPaused(
        bytes32 indexed schainHash
    );

    /**
     * @dev Emitted when the schain is resumed
     */
    event SchainResumed(
        bytes32 indexed schainHash
    );

   /**
     * @dev Emitted when reimbursed contract was added
     */
    event ReimbursedContractAdded(
        bytes32 indexed schainHash,
        address contractAddress
    );

   /**
     * @dev Emitted when reimbursed contract was removed
     */
    event ReimbursedContractRemoved(
        bytes32 indexed schainHash,
        address contractAddress
    );

    /**
     * @dev Reentrancy guard for postIncomingMessages.
     */
    modifier messageInProgressLocker() {
        require(!messageInProgress, "Message is in progress");
        messageInProgress = true;
        _;
        messageInProgress = false;
    }

    /**
     * @dev Modifier to make a function callable only when IMA is active.
     */
    modifier whenNotPaused(bytes32 schainHash) {
        require(!isPaused(schainHash), "IMA is paused");
        _;
    }

    /**
     * @dev Allows `msg.sender` to connect schain with MessageProxyOnMainnet for transferring messages.
     *
     * Requirements:
     *
     * - Schain name must not be `Mainnet`.
     */
    function addConnectedChain(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(ISchainsInternal(
            contractManagerOfSkaleManager.getContract("SchainsInternal")
        ).isSchainExist(schainHash), "SKALE chain must exist");
        _addConnectedChain(schainHash);
    }

    /**
     * @dev Allows owner of the contract to set CommunityPool address for gas reimbursement.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as DEFAULT_ADMIN_ROLE.
     * - Address of CommunityPool contract must not be null.
     */
    function setCommunityPool(ICommunityPool newCommunityPoolAddress) external override onlyOwner {
        require(address(newCommunityPoolAddress) != address(0), "CommunityPool address has to be set");
        communityPool = newCommunityPoolAddress;
    }

    /**
     * @dev Allows `msg.sender` to register extra contract for being able to transfer messages from custom contracts.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Schain name must not be `Mainnet`.
     */
    function registerExtraContract(string memory schainName, address extraContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        _registerExtraContract(schainHash, extraContract);
    }

    /**
     * @dev Allows `msg.sender` to remove extra contract,
     * thus `extraContract` will no longer be available to transfer messages from mainnet to schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Schain name must not be `Mainnet`.
     */
    function removeExtraContract(string memory schainName, address extraContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        _removeExtraContract(schainHash, extraContract);
        if (_reimbursedContracts[schainHash].contains(extraContract)) {
            _removeReimbursedContract(schainHash, extraContract);
        }
    }

    /**
     * @dev Allows `msg.sender` to add reimbursed contract for being able to reimburse gas amount from CommunityPool
     * during message transfers from custom contracts.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE or owner of given `schainName`.
     * - Schain name must not be `Mainnet`.
     * - `reimbursedContract` should be registered as extra contract
     */
    function addReimbursedContract(string memory schainName, address reimbursedContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");        
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to add reimbursed contract"
        );
        require(reimbursedContract.isContract(), "Given address is not a contract");
        require(isContractRegistered(schainHash, reimbursedContract), "Contract is not registered");
        require(!_reimbursedContracts[schainHash].contains(reimbursedContract), "Reimbursed contract is already added");
        _reimbursedContracts[schainHash].add(reimbursedContract);
        emit ReimbursedContractAdded(schainHash, reimbursedContract);
    }

    /**
     * @dev Allows `msg.sender` to remove reimbursed contract,
     * thus `reimbursedContract` will no longer be available to reimburse gas amount from CommunityPool during
     * message transfers from mainnet to schain.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE or owner of given `schainName`.
     * - Schain name must not be `Mainnet`.
     */
    function removeReimbursedContract(string memory schainName, address reimbursedContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to remove reimbursed contract"
        );
        require(_reimbursedContracts[schainHash].contains(reimbursedContract), "Reimbursed contract is not added");
        _removeReimbursedContract(schainHash, reimbursedContract);
    }

    /**
     * @dev Posts incoming message from `fromSchainName`.
     *
     * Requirements:
     *
     * - `msg.sender` must be authorized caller.
     * - `fromSchainName` must be initialized.
     * - `startingCounter` must be equal to the chain's incoming message counter.
     * - If destination chain is Mainnet, message signature must be valid.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    )
        external
        override(IMessageProxy, MessageProxy)
        messageInProgressLocker
        whenNotPaused(keccak256(abi.encodePacked(fromSchainName)))
    {
        uint256 gasTotal = gasleft();
        bytes32 fromSchainHash = keccak256(abi.encodePacked(fromSchainName));
        require(isAgentAuthorized(fromSchainHash, msg.sender), "Agent is not authorized");
        require(_checkSchainBalance(fromSchainHash), "Schain wallet has not enough funds");
        require(connectedChains[fromSchainHash].inited, "Chain is not initialized");
        require(messages.length <= MESSAGES_LENGTH, "Too many messages");
        require(
            startingCounter == connectedChains[fromSchainHash].incomingMessageCounter,
            "Starting counter is not equal to incoming message counter");

        require(_verifyMessages(
            fromSchainName,
            _hashedArray(messages, startingCounter, fromSchainName), sign),
            "Signature is not verified");
        uint additionalGasPerMessage =
            (gasTotal - gasleft() + headerMessageGasCost + messages.length * messageGasCost) / messages.length;
        uint notReimbursedGas = 0;
        connectedChains[fromSchainHash].incomingMessageCounter += messages.length;
        for (uint256 i = 0; i < messages.length; i++) {
            gasTotal = gasleft();
            if (isReimbursedContract(fromSchainHash, messages[i].destinationContract)) {
                address receiver = _getGasPayer(fromSchainHash, messages[i], startingCounter + i);
                _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
                notReimbursedGas += communityPool.refundGasByUser(
                    fromSchainHash,
                    payable(msg.sender),
                    receiver,
                    gasTotal - gasleft() + additionalGasPerMessage
                );
            } else {
                _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
                notReimbursedGas += gasTotal - gasleft() + additionalGasPerMessage;
            }
        }
        communityPool.refundGasBySchainWallet(fromSchainHash, payable(msg.sender), notReimbursedGas);
    }

    /**
     * @dev Sets headerMessageGasCost to a new value.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewHeaderMessageGasCost(uint256 newHeaderMessageGasCost) external override onlyConstantSetter {
        emit GasCostMessageHeaderWasChanged(headerMessageGasCost, newHeaderMessageGasCost);
        headerMessageGasCost = newHeaderMessageGasCost;
    }

    /**
     * @dev Sets messageGasCost to a new value.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewMessageGasCost(uint256 newMessageGasCost) external override onlyConstantSetter {
        emit GasCostMessageWasChanged(messageGasCost, newMessageGasCost);
        messageGasCost = newMessageGasCost;
    }

    /**
     * @dev Sets new version of contracts on mainnet
     *
     * Requirements:
     *
     * - `msg.sender` must be granted DEFAULT_ADMIN_ROLE.
     */
    function setVersion(string calldata newVersion) external override onlyOwner {
        emit VersionUpdated(version, newVersion);
        version = newVersion;
    }

    /**
     * @dev Allows PAUSABLE_ROLE to pause IMA bridge unlimited
     *
     * Requirements:
     *
     * - IMA bridge to current schain was not paused
     * - Sender should be PAUSABLE_ROLE
     */
    function pause(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(hasRole(PAUSABLE_ROLE, msg.sender), "Incorrect sender");
        require(!pauseInfo[schainHash].paused, "Already paused");
        pauseInfo[schainHash].paused = true;
        emit SchainPaused(schainHash);
    }

/**
     * @dev Allows DEFAULT_ADMIN_ROLE or schain owner to resume IMA bridge
     *
     * Requirements:
     *
     * - IMA bridge to current schain was paused
     * - Sender should be DEFAULT_ADMIN_ROLE or schain owner
     */
    function resume(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || isSchainOwner(msg.sender, schainHash), "Incorrect sender");
        require(pauseInfo[schainHash].paused, "Already unpaused");
        pauseInfo[schainHash].paused = false;
        emit SchainResumed(schainHash);
    }

    /**
     * @dev Should return length of reimbursed contracts by schainHash.
     */
    function getReimbursedContractsLength(bytes32 schainHash) external view override returns (uint256) {
        return _reimbursedContracts[schainHash].length();
    }

    /**
     * @dev Should return a range of reimbursed contracts by schainHash.
     * 
     * Requirements:
     * range should be less or equal 10 contracts
     */
    function getReimbursedContractsRange(
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
            from < to && to - from <= 10 && to <= _reimbursedContracts[schainHash].length(),
            "Range is incorrect"
        );
        contractsInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            contractsInRange[i - from] = _reimbursedContracts[schainHash].at(i);
        }
    }

    /**
     * @dev Creates a new MessageProxyForMainnet contract.
     */
    function initialize(IContractManager contractManagerOfSkaleManagerValue) public virtual override initializer {
        SkaleManagerClient.initialize(contractManagerOfSkaleManagerValue);
        MessageProxy.initializeMessageProxy(1e6);
        headerMessageGasCost = 92251;
        messageGasCost = 9000;
    }

    /**
     * @dev PostOutgoingMessage function with whenNotPaused modifier
     */
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    )
        public
        override(IMessageProxy, MessageProxy)
        whenNotPaused(targetChainHash)
    {
        super.postOutgoingMessage(targetChainHash, targetContract, data);
    }

    /**
     * @dev Checks whether chain is currently connected.
     *
     * Note: Mainnet chain does not have a public key, and is implicitly
     * connected to MessageProxy.
     *
     * Requirements:
     *
     * - `schainName` must not be Mainnet.
     */
    function isConnectedChain(
        string memory schainName
    )
        public
        view
        override(IMessageProxy, MessageProxy)
        returns (bool)
    {
        require(keccak256(abi.encodePacked(schainName)) != MAINNET_HASH, "Schain id can not be equal Mainnet");
        return super.isConnectedChain(schainName);
    }

    /**
     * @dev Returns true if IMA to schain is paused.
     */
    function isPaused(bytes32 schainHash) public view override returns (bool) {
        return pauseInfo[schainHash].paused;
    }

    /**
     * @dev Returns true if message to the contract should be reimbursed from CommunityPool.
     */
    function isReimbursedContract(bytes32 schainHash, address contractAddress) public view override returns (bool) {
        return
            isContractRegistered(bytes32(0), contractAddress) ||
            _reimbursedContracts[schainHash].contains(contractAddress);
    }

    // private

    function _authorizeOutgoingMessageSender(bytes32 targetChainHash) internal view override {
        require(
            isContractRegistered(bytes32(0), msg.sender)
                || isContractRegistered(targetChainHash, msg.sender)
                || isSchainOwner(msg.sender, targetChainHash),
            "Sender contract is not registered"
        );
    }

    /**
     * @dev Converts calldata structure to memory structure and checks
     * whether message BLS signature is valid.
     */
    function _verifyMessages(
        string calldata fromSchainName,
        bytes32 hashedMessages,
        MessageProxyForMainnet.Signature calldata sign
    )
        internal
        view
        returns (bool)
    {
        return ISchains(
            contractManagerOfSkaleManager.getContract("Schains")
        ).verifySchainSignature(
            sign.blsSignature[0],
            sign.blsSignature[1],
            hashedMessages,
            sign.counter,
            sign.hashA,
            sign.hashB,
            fromSchainName
        );
    }

    /**
     * @dev Checks whether balance of schain wallet is sufficient for
     * for reimbursement custom message.
     */
    function _checkSchainBalance(bytes32 schainHash) internal view returns (bool) {
        return IWallets(
            payable(contractManagerOfSkaleManager.getContract("Wallets"))
        ).getSchainBalance(schainHash) >= (MESSAGES_LENGTH + 1) * gasLimit * tx.gasprice;
    }

    /**
     * @dev Returns list of registered custom extra contracts.
     */
    function _getRegistryContracts()
        internal
        view
        override
        returns (mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) storage)
    {
        return _registryContracts;
    }


    function _removeReimbursedContract(bytes32 schainHash, address reimbursedContract) private {
        _reimbursedContracts[schainHash].remove(reimbursedContract);
        emit ReimbursedContractRemoved(schainHash, reimbursedContract);
    }
}