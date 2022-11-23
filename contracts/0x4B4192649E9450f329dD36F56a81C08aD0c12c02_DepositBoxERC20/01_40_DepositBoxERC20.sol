// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBoxERC20.sol - SKALE Interchain Messaging Agent
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
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/DoubleEndedQueueUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@skalenetwork/ima-interfaces/mainnet/DepositBoxes/IDepositBoxERC20.sol";

import "../../Messages.sol";
import "../DepositBox.sol";

interface IERC20TransferVoid {
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
}


/**
 * @title DepositBoxERC20
 * @dev Runs on mainnet,
 * accepts messages from schain,
 * stores deposits of ERC20.
 */
contract DepositBoxERC20 is DepositBox, IDepositBoxERC20 {
    using AddressUpgradeable for address;
    using DoubleEndedQueueUpgradeable for DoubleEndedQueueUpgradeable.Bytes32Deque;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum DelayedTransferStatus {
        DELAYED,
        ARBITRAGE,
        COMPLETED
    }

    struct DelayedTransfer {
        address receiver;
        bytes32 schainHash;
        address token;
        uint256 amount;
        uint256 untilTimestamp;
        DelayedTransferStatus status;
    }

    struct DelayConfig {
        // token address => value
        mapping(address => uint256) bigTransferThreshold;
        EnumerableSetUpgradeable.AddressSet trustedReceivers;
        uint256 transferDelay;
        uint256 arbitrageDuration;
    }

    uint256 private constant _QUEUE_PROCESSING_LIMIT = 10;

    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    // schainHash => address of ERC20 on Mainnet
    // Deprecated
    // slither-disable-next-line unused-state
    mapping(bytes32 => mapping(address => bool)) private _deprecatedSchainToERC20;
    mapping(bytes32 => mapping(address => uint256)) public transferredAmount;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _schainToERC20;

    // exits delay configuration
    //   schainHash => delay config
    mapping(bytes32 => DelayConfig) private _delayConfig;

    uint256 public delayedTransfersSize;
    // delayed transfer id => delayed transfer
    mapping(uint256 => DelayedTransfer) public delayedTransfers;
    // receiver address => delayed transfers ids queue
    mapping(address => DoubleEndedQueueUpgradeable.Bytes32Deque) public delayedTransfersByReceiver;

    /**
     * @dev Emitted when token is mapped in DepositBoxERC20.
     */
    event ERC20TokenAdded(string schainName, address indexed contractOnMainnet);

    /**
     * @dev Emitted when token is received by DepositBox and is ready to be cloned
     * or transferred on SKALE chain.
     */
    event ERC20TokenReady(address indexed contractOnMainnet, uint256 amount);

    event TransferDelayed(uint256 id, address receiver, address token, uint256 amount);

    event Escalated(uint256 id);

    /**
     * @dev Emitted when token transfer is skipped due to internal token error
     */
    event TransferSkipped(uint256 id);

    /**
     * @dev Emitted when big transfer threshold is changed
     */
    event BigTransferThresholdIsChanged(
        bytes32 indexed schainHash,
        address indexed token,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when big transfer delay is changed
     */
    event BigTransferDelayIsChanged(
        bytes32 indexed schainHash,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when arbitrage duration is changed
     */
    event ArbitrageDurationIsChanged(
        bytes32 indexed schainHash,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Allows `msg.sender` to send ERC20 token from mainnet to schain
     *
     * Requirements:
     *
     * - Schain name must not be `Mainnet`.
     * - Receiver account on schain cannot be null.
     * - Schain that receives tokens should not be killed.
     * - Receiver contract should be defined.
     * - `msg.sender` should approve their tokens for DepositBoxERC20 address.
     */
    function depositERC20(
        string calldata schainName,
        address erc20OnMainnet,
        uint256 amount
    )
        external
        override
        rightTransaction(schainName, msg.sender)
        whenNotKilled(_schainHash(schainName))
    {
        bytes32 schainHash = _schainHash(schainName);
        address contractReceiver = schainLinks[schainHash];
        require(contractReceiver != address(0), "Unconnected chain");
        require(
            IERC20MetadataUpgradeable(erc20OnMainnet).allowance(msg.sender, address(this)) >= amount,
            "DepositBox was not approved for ERC20 token"
        );
        bytes memory data = _receiveERC20(
            schainName,
            erc20OnMainnet,
            msg.sender,
            amount
        );
        _saveTransferredAmount(schainHash, erc20OnMainnet, amount);
        IERC20MetadataUpgradeable(erc20OnMainnet).safeTransferFrom(msg.sender, address(this), amount);
        messageProxy.postOutgoingMessage(
            schainHash,
            contractReceiver,
            data
        );
    }

    /**
     * @dev Allows MessageProxyForMainnet contract to execute transferring ERC20 token from schain to mainnet.
     *
     * Requirements:
     *
     * - Schain from which the tokens came should not be killed.
     * - Sender contract should be defined and schain name cannot be `Mainnet`.
     * - Amount of tokens on DepositBoxERC20 should be equal or more than transferred amount.
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
        Messages.TransferErc20Message memory message = Messages.decodeTransferErc20Message(data);
        require(message.token.isContract(), "Given address is not a contract");
        require(
            IERC20MetadataUpgradeable(message.token).balanceOf(address(this)) >= message.amount,
            "Not enough money"
        );
        _removeTransferredAmount(schainHash, message.token, message.amount);

        uint256 delay = _delayConfig[schainHash].transferDelay;
        if (
            delay > 0
            && _delayConfig[schainHash].bigTransferThreshold[message.token] <= message.amount
            && !isReceiverTrusted(schainHash, message.receiver)
        ) {
            _createDelayedTransfer(schainHash, message, delay);
        } else {
            IERC20MetadataUpgradeable(message.token).safeTransfer(message.receiver, message.amount);
        }
    }

    /**
     * @dev Allows Schain owner to add an ERC20 token to DepositBoxERC20.
     *
     * Emits an {ERC20TokenAdded} event.
     *
     * Requirements:
     *
     * - Schain should not be killed.
     * - Only owner of the schain able to run function.
     */
    function addERC20TokenByOwner(string calldata schainName, address erc20OnMainnet)
        external
        override
        onlySchainOwner(schainName)
        whenNotKilled(_schainHash(schainName))
    {
        _addERC20ForSchain(schainName, erc20OnMainnet);
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
    function getFunds(string calldata schainName, address erc20OnMainnet, address receiver, uint amount)
        external
        override
        onlySchainOwner(schainName)
        whenKilled(_schainHash(schainName))
    {
        bytes32 schainHash = _schainHash(schainName);
        require(transferredAmount[schainHash][erc20OnMainnet] >= amount, "Incorrect amount");
        _removeTransferredAmount(schainHash, erc20OnMainnet, amount);
        IERC20MetadataUpgradeable(erc20OnMainnet).safeTransfer(receiver, amount);
    }

    /**
     * @dev Set a threshold amount of tokens.
     * If amount of tokens that exits IMA is bigger than the threshold
     * the transfer is delayed for configurable amount of time
     * and can be canceled by a voting
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     */
    function setBigTransferValue(
        string calldata schainName,
        address token,
        uint256 value
    )
        external
        override
        onlySchainOwner(schainName)
    {
        bytes32 schainHash = _schainHash(schainName);
        emit BigTransferThresholdIsChanged(
            schainHash,
            token,
            _delayConfig[schainHash].bigTransferThreshold[token],
            value
        );
        _delayConfig[schainHash].bigTransferThreshold[token] = value;
    }

    /**
     * @dev Set a time delay.
     * If amount of tokens that exits IMA is bigger than a threshold
     * the transfer is delayed for set amount of time
     * and can be canceled by a voting
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     */
    function setBigTransferDelay(
        string calldata schainName,
        uint256 delayInSeconds
    )
        external
        override
        onlySchainOwner(schainName)
    {
        bytes32 schainHash = _schainHash(schainName);
        // need to restrict big delays to avoid overflow
        require(delayInSeconds < 1e8, "Delay is too big"); // no more then ~ 3 years
        emit BigTransferDelayIsChanged(schainHash, _delayConfig[schainHash].transferDelay, delayInSeconds);
        _delayConfig[schainHash].transferDelay = delayInSeconds;
    }

    /**
     * @dev Set an arbitrage.
     * After escalation the transfer is locked for provided period of time.
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     */
    function setArbitrageDuration(
        string calldata schainName,
        uint256 delayInSeconds
    )
        external
        override
        onlySchainOwner(schainName)
    {
        bytes32 schainHash = _schainHash(schainName);
        // need to restrict big delays to avoid overflow
        require(delayInSeconds < 1e8, "Delay is too big"); // no more then ~ 3 years
        emit ArbitrageDurationIsChanged(schainHash, _delayConfig[schainHash].arbitrageDuration, delayInSeconds);
        _delayConfig[schainHash].arbitrageDuration = delayInSeconds;
    }

    /**
     * @dev Add the address to a whitelist of addresses that can do big transfers without delaying
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - the address must not be in the whitelist
     */
    function trustReceiver(
        string calldata schainName,
        address receiver
    )
        external
        override
        onlySchainOwner(schainName)
    {
        require(
            _delayConfig[_schainHash(schainName)].trustedReceivers.add(receiver),
            "Receiver already is trusted"
        );
    }

    /**
     * @dev Remove the address from a whitelist of addresses that can do big transfers without delaying
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - the address must be in the whitelist
     */
    function stopTrustingReceiver(
        string calldata schainName,
        address receiver
    )
        external
        override
        onlySchainOwner(schainName)
    {
        require(_delayConfig[_schainHash(schainName)].trustedReceivers.remove(receiver), "Receiver is not trusted");
    }

    /**
     * @dev Transfers tokens that was locked for delay during exit process.
     * Must be called by a receiver.
     */
    function retrieve() external override {
        retrieveFor(msg.sender);
    }

    /**
     * @dev Initialize arbitrage of a suspicious big transfer
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain or have ARBITER_ROLE role
     * - transfer must be delayed and arbitrage must not be started
     */
    function escalate(uint256 transferId) external override {
        bytes32 schainHash = delayedTransfers[transferId].schainHash;
        require(
            hasRole(ARBITER_ROLE, msg.sender) || isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to request escalation"
        );
        require(delayedTransfers[transferId].status == DelayedTransferStatus.DELAYED, "The transfer has to be delayed");
        delayedTransfers[transferId].status = DelayedTransferStatus.ARBITRAGE;
        delayedTransfers[transferId].untilTimestamp = MathUpgradeable.max(
            delayedTransfers[transferId].untilTimestamp,
            block.timestamp + _delayConfig[schainHash].arbitrageDuration
        );
        emit Escalated(transferId);
    }

    /**
     * @dev Approve a big transfer and immidiately transfer tokens during arbitrage
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - arbitrage of the transfer must be started
     */
    function validateTransfer(
        uint transferId
    )
        external
        override
        onlySchainOwnerByHash(delayedTransfers[transferId].schainHash)
    {
        DelayedTransfer storage transfer = delayedTransfers[transferId];
        require(transfer.status == DelayedTransferStatus.ARBITRAGE, "Arbitrage has to be active");
        transfer.status = DelayedTransferStatus.COMPLETED;
        delete transfer.untilTimestamp;
        IERC20MetadataUpgradeable(transfer.token).safeTransfer(transfer.receiver, transfer.amount);
    }

    /**
     * @dev Reject a big transfer and transfer tokens to SKALE chain owner during arbitrage
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - arbitrage of the transfer must be started
     */
    function rejectTransfer(
        uint transferId
    )
        external
        override
        onlySchainOwnerByHash(delayedTransfers[transferId].schainHash)
    {
        DelayedTransfer storage transfer = delayedTransfers[transferId];
        require(transfer.status == DelayedTransferStatus.ARBITRAGE, "Arbitrage has to be active");
        transfer.status = DelayedTransferStatus.COMPLETED;
        delete transfer.untilTimestamp;
        // msg.sender is schain owner
        IERC20MetadataUpgradeable(transfer.token).safeTransfer(msg.sender, transfer.amount);
    }

    function doTransfer(address token, address receiver, uint256 amount) external override {
        require(msg.sender == address(this), "Internal use only");
        IERC20Upgradeable(token).safeTransfer(receiver, amount);
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
        Messages.TransferErc20Message memory message = Messages.decodeTransferErc20Message(data);
        return message.receiver;
    }

    /**
     * @dev Should return true if token was added by Schain owner or
     * added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToERC20(
        string calldata schainName,
        address erc20OnMainnet
    )
        external
        view
        override
        returns (bool)
    {
        return _schainToERC20[_schainHash(schainName)].contains(erc20OnMainnet);
    }

    /**
     * @dev Should return length of a set of all mapped tokens which were added by Schain owner
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC20Length(string calldata schainName) external view override returns (uint256) {
        return _schainToERC20[_schainHash(schainName)].length();
    }

    /**
     * @dev Should return an array of range of tokens were added by Schain owner
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC20(
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
            from < to && to - from <= 10 && to <= _schainToERC20[_schainHash(schainName)].length(),
            "Range is incorrect"
        );
        tokensInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            tokensInRange[i - from] = _schainToERC20[_schainHash(schainName)].at(i);
        }
    }

    /**
     * @dev Get amount of tokens that are delayed for specified receiver
     */
    function getDelayedAmount(address receiver, address token) external view override returns (uint256 value) {
        uint256 delayedTransfersAmount = delayedTransfersByReceiver[receiver].length();
        for (uint256 i = 0; i < delayedTransfersAmount; ++i) {
            DelayedTransfer storage transfer = delayedTransfers[uint256(delayedTransfersByReceiver[receiver].at(i))];
            DelayedTransferStatus status = transfer.status;
            if (transfer.token == token) {
                if (status == DelayedTransferStatus.DELAYED || status == DelayedTransferStatus.ARBITRAGE) {
                    value += transfer.amount;
                }
            }
        }
    }

    /**
     * @dev Get timestamp of next unlock of tokens that are delayed for specified receiver
     */
    function getNextUnlockTimestamp(
        address receiver,
        address token
    )
        external
        view
        override
        returns (uint256 unlockTimestamp)
    {
        uint256 delayedTransfersAmount = delayedTransfersByReceiver[receiver].length();
        unlockTimestamp = type(uint256).max;
        for (uint256 i = 0; i < delayedTransfersAmount; ++i) {
            DelayedTransfer storage transfer = delayedTransfers[uint256(delayedTransfersByReceiver[receiver].at(i))];
            DelayedTransferStatus status = transfer.status;
            if (transfer.token == token) {
                if (status != DelayedTransferStatus.COMPLETED) {
                    unlockTimestamp = MathUpgradeable.min(unlockTimestamp, transfer.untilTimestamp);
                }
                if (status == DelayedTransferStatus.DELAYED) {
                    break;
                }
            }
        }
    }

    /**
     * @dev Get amount of addresses that are added to the whitelist
     */
    function getTrustedReceiversAmount(bytes32 schainHash) external view override returns (uint256) {
        return _delayConfig[schainHash].trustedReceivers.length();
    }

    /**
     * @dev Get i-th address of the whitelist
     */
    function getTrustedReceiver(string calldata schainName, uint256 index) external view override returns (address) {
        return _delayConfig[_schainHash(schainName)].trustedReceivers.at(index);
    }

    /**
     * @dev Get amount of tokens that are considered as a big transfer
     */
    function getBigTransferThreshold(bytes32 schainHash, address token) external view override returns (uint256) {
        return _delayConfig[schainHash].bigTransferThreshold[token];
    }

    /**
     * @dev Get time delay of big transfers
     */
    function getTimeDelay(bytes32 schainHash) external view override returns (uint256) {
        return _delayConfig[schainHash].transferDelay;
    }

    /**
     * @dev Get duration of an arbitrage
     */
    function getArbitrageDuration(bytes32 schainHash) external view override returns (uint256) {
        return _delayConfig[schainHash].arbitrageDuration;
    }

    /**
     * @dev Retrive tokens that were unlocked after delay for specified receiver
     */
    function retrieveFor(address receiver) public override {
        uint256 transfersAmount = MathUpgradeable.min(
            delayedTransfersByReceiver[receiver].length(),
            _QUEUE_PROCESSING_LIMIT
        );

        uint256 currentIndex = 0;
        bool retrieved = false;
        for (uint256 i = 0; i < transfersAmount; ++i) {
            uint256 transferId = uint256(delayedTransfersByReceiver[receiver].at(currentIndex));
            DelayedTransfer memory transfer = delayedTransfers[transferId];
            ++currentIndex;

            if (transfer.status != DelayedTransferStatus.COMPLETED) {
                if (block.timestamp < transfer.untilTimestamp) {
                    // disable detector untill slither fixes false positive
                    // https://github.com/crytic/slither/issues/778
                    // slither-disable-next-line incorrect-equality
                    if (transfer.status == DelayedTransferStatus.DELAYED) {
                        break;
                    } else {
                        // status is ARBITRAGE
                        continue;
                    }
                } else {
                    // it's time to unlock
                    if (currentIndex == 1) {
                        --currentIndex;
                        _removeOldestDelayedTransfer(receiver);
                    } else {
                        delayedTransfers[transferId].status = DelayedTransferStatus.COMPLETED;
                    }
                    retrieved = true;
                    try
                        this.doTransfer(transfer.token, transfer.receiver, transfer.amount)
                    // solhint-disable-next-line no-empty-blocks
                    {}
                    catch {
                        emit TransferSkipped(transferId);
                    }
                }
            } else {
                // status is COMPLETED
                if (currentIndex == 1) {
                    --currentIndex;
                    retrieved = true;
                    _removeOldestDelayedTransfer(receiver);
                }
            }
        }
        require(retrieved, "There are no transfers available for retrieving");
    }

    /**
     * @dev Creates a new DepositBoxERC20 contract.
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
    }

    /**
     * @dev Check if the receiver is in the delay whitelist
     */
    function isReceiverTrusted(bytes32 schainHash, address receiver) public view override returns (bool) {
        return _delayConfig[schainHash].trustedReceivers.contains(receiver);
    }

    // private

    /**
     * @dev Saves amount of tokens that was transferred to schain.
     */
    function _saveTransferredAmount(bytes32 schainHash, address erc20Token, uint256 amount) private {
        transferredAmount[schainHash][erc20Token] += amount;
    }

    /**
     * @dev Removes amount of tokens that was transferred from schain.
     */
    function _removeTransferredAmount(bytes32 schainHash, address erc20Token, uint256 amount) private {
        transferredAmount[schainHash][erc20Token] -= amount;
    }

    /**
     * @dev Allows DepositBoxERC20 to receive ERC20 tokens.
     *
     * Emits an {ERC20TokenReady} event.
     *
     * Requirements:
     *
     * - Amount must be less than or equal to the total supply of the ERC20 contract.
     * - Whitelist should be turned off for auto adding tokens to DepositBoxERC20.
     */
    function _receiveERC20(
        string calldata schainName,
        address erc20OnMainnet,
        address to,
        uint256 amount
    )
        private
        returns (bytes memory data)
    {
        bytes32 schainHash = _schainHash(schainName);
        IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(erc20OnMainnet);
        uint256 totalSupply = erc20.totalSupply();
        require(amount <= totalSupply, "Amount is incorrect");
        bool isERC20AddedToSchain = _schainToERC20[schainHash].contains(erc20OnMainnet);
        if (!isERC20AddedToSchain) {
            require(!isWhitelisted(schainName), "Whitelist is enabled");
            _addERC20ForSchain(schainName, erc20OnMainnet);
            data = Messages.encodeTransferErc20AndTokenInfoMessage(
                erc20OnMainnet,
                to,
                amount,
                _getErc20TotalSupply(erc20),
                _getErc20TokenInfo(erc20)
            );
        } else {
            data = Messages.encodeTransferErc20AndTotalSupplyMessage(
                erc20OnMainnet,
                to,
                amount,
                _getErc20TotalSupply(erc20)
            );
        }
        emit ERC20TokenReady(erc20OnMainnet, amount);
    }

    /**
     * @dev Adds an ERC20 token to DepositBoxERC20.
     *
     * Emits an {ERC20TokenAdded} event.
     *
     * Requirements:
     *
     * - Given address should be contract.
     */
    function _addERC20ForSchain(string calldata schainName, address erc20OnMainnet) private {
        bytes32 schainHash = _schainHash(schainName);
        require(erc20OnMainnet.isContract(), "Given address is not a contract");
        require(!_schainToERC20[schainHash].contains(erc20OnMainnet), "ERC20 Token was already added");
        _schainToERC20[schainHash].add(erc20OnMainnet);
        emit ERC20TokenAdded(schainName, erc20OnMainnet);
    }

    /**
     * @dev Add delayed transfer to receiver specific queue
     */
    function _addToDelayedQueue(
        address receiver,
        uint256 id,
        uint256 until
    )
        private
    {
        _addToDelayedQueueWithPriority(delayedTransfersByReceiver[receiver], id, until, _QUEUE_PROCESSING_LIMIT);
    }

    /**
     * @dev Add delayed transfer to receiver specific queue at the position
     * that maintains order from earlier unlocked to later unlocked.
     * If the position is located further than depthLimit from the back
     * the element is added at back - depthLimit index
     */
    function _addToDelayedQueueWithPriority(
        DoubleEndedQueueUpgradeable.Bytes32Deque storage queue,
        uint256 id,
        uint256 until,
        uint256 depthLimit
    )
        private
    {
        if (depthLimit == 0 || queue.empty()) {
            queue.pushBack(bytes32(id));
        } else {
            if (delayedTransfers[uint256(queue.back())].untilTimestamp <= until) {
                queue.pushBack(bytes32(id));
            } else {
                bytes32 lowPriorityValue = queue.popBack();
                _addToDelayedQueueWithPriority(queue, id, until, depthLimit - 1);
                queue.pushBack(lowPriorityValue);
            }
        }
    }

    /**
     * Create instance of DelayedTransfer and initialize all auxiliary fields.
     */
    function _createDelayedTransfer(
        bytes32 schainHash,
        Messages.TransferErc20Message memory message,
        uint256 delay
    )
        private
    {
        uint256 delayId = delayedTransfersSize++;
        delayedTransfers[delayId] = DelayedTransfer({
            receiver: message.receiver,
            schainHash: schainHash,
            token: message.token,
            amount: message.amount,
            untilTimestamp: block.timestamp + delay,
            status: DelayedTransferStatus.DELAYED
        });
        _addToDelayedQueue(message.receiver, delayId, block.timestamp + delay);
        emit TransferDelayed(delayId, message.receiver, message.token, message.amount);
    }

    /**
     * Remove instance of DelayedTransfer and clean auxiliary fields.
     */
    function _removeOldestDelayedTransfer(address receiver) private {
        uint256 transferId = uint256(delayedTransfersByReceiver[receiver].popFront());
        // For most cases the loop will have only 1 iteration.
        // In worst case the amount of iterations is limited by _QUEUE_PROCESSING_LIMIT
        // slither-disable-next-line costly-loop
        delete delayedTransfers[transferId];
    }

    /**
     * @dev Returns total supply of ERC20 token.
     */
    function _getErc20TotalSupply(IERC20MetadataUpgradeable erc20Token) private view returns (uint256) {
        return erc20Token.totalSupply();
    }

    /**
     * @dev Returns info about ERC20 token such as token name, decimals, symbol.
     */
    function _getErc20TokenInfo(IERC20MetadataUpgradeable erc20Token)
        private
        view
        returns (Messages.Erc20TokenInfo memory)
    {
        return Messages.Erc20TokenInfo({
            name: erc20Token.name(),
            decimals: erc20Token.decimals(),
            symbol: erc20Token.symbol()
        });
    }
}