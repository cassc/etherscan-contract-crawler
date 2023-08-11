// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {ISouqTimelock} from "../interfaces/ISouqTimelock.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title SouqTimelock
 * @author Souq.Finance
 * @notice This contract implements a timelock mechanism similar to TimelockController.sol by openzeppelin
 * @notice Original https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5ae630684a0f57de400ef69499addab4c32ac8fb/contracts/governance/TimelockController.sol
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */

contract SouqTimelock is Initializable, OwnableUpgradeable, UUPSUpgradeable, ISouqTimelock {
    using SafeMath for uint;
    uint256 public version;
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);
    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    IAddressesRegistry public registry;

    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    /// @inheritdoc ISouqTimelock
    function initialize(uint _delay, address _registry) external initializer {
        version = 1;
        _minDelay = _delay;
        registry = IAddressesRegistry(_registry);
        __Ownable_init();
    }

    /**
     * @dev modifier for when the address has updgrader admin role
     */
    modifier onlyUpdater() {
        require(IAccessManager(registry.getAccessManager()).isUpgraderAdmin(msg.sender), Errors.CALLER_NOT_UPGRADER);
        _;
    }

    /**
     * @dev modifier for when the address has timelock admin role
     */
    modifier onlyTimelockAdmin() {
        require(IAccessManager(registry.getAccessManager()).isTimelockAdmin(msg.sender), Errors.CALLER_NOT_TIMELOCK_ADMIN);
        _;
    }

    /// @inheritdoc ISouqTimelock
    function isTransaction(bytes32 id) public view returns (bool) {
        return getTransactionState(id) != TransactionState.Unset;
    }

    /// @inheritdoc ISouqTimelock
    function isTransactionPending(bytes32 id) external view returns (bool) {
        TransactionState state = getTransactionState(id);
        return state == TransactionState.Waiting || state == TransactionState.Ready;
    }

    /// @inheritdoc ISouqTimelock
    function isTransactionReady(bytes32 id) public view returns (bool) {
        return getTransactionState(id) == TransactionState.Ready;
    }

    /// @inheritdoc ISouqTimelock
    function isTransactionDone(bytes32 id) public view returns (bool) {
        return getTransactionState(id) == TransactionState.Done;
    }

    /// @inheritdoc ISouqTimelock
    function getTimestamp(bytes32 id) public view virtual returns (uint256) {
        return _timestamps[id];
    }

    /// @inheritdoc ISouqTimelock
    function getMinDelay() public view virtual returns (uint256) {
        return _minDelay;
    }

    /// @inheritdoc ISouqTimelock
    function getTransactionState(bytes32 id) public view virtual returns (TransactionState) {
        uint256 timestamp = getTimestamp(id);
        if (timestamp == 0) {
            return TransactionState.Unset;
        } else if (timestamp == _DONE_TIMESTAMP) {
            return TransactionState.Done;
        } else if (timestamp > getBlockTimeStamp()) {
            return TransactionState.Waiting;
        } else {
            return TransactionState.Ready;
        }
    }

    /// @inheritdoc ISouqTimelock
    function getBlockTimeStamp() public view returns (uint256) {
        //Using block.timestamp is safer than block number
        //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
        return block.timestamp;
    }

    /// @inheritdoc ISouqTimelock
    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external onlyTimelockAdmin returns (bytes32) {
        require(eta >= getBlockTimeStamp().add(getMinDelay()), Errors.TIMELOCK_ETA_MUST_SATISFY_DELAY);
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(!isTransaction(txHash), Errors.TIMELOCK_TRANSACTION_ALREADY_QUEUED);
        _timestamps[txHash] = eta;
        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    /// @inheritdoc ISouqTimelock
    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external onlyTimelockAdmin {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(!isTransactionDone(txHash), Errors.TIMELOCK_TRANSACTION_ALREADY_EXECUTED);
        delete _timestamps[txHash];
        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    /// @inheritdoc ISouqTimelock
    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external payable onlyTimelockAdmin returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(isTransactionReady(txHash), Errors.TIMELOCK_TRANSACTION_NOT_READY);
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        AddressUpgradeable.verifyCallResult(success, returnData, "TIMELOCK_TRANSACTION_EXECUTION_REVERTED");
        _timestamps[txHash] = _DONE_TIMESTAMP;

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    /// @inheritdoc ISouqTimelock
    function updateDelay(uint256 newDelay) external virtual onlyTimelockAdmin {
        emit NewDelay(newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev Internal function to permit the upgrade of the proxy.
     * @param newImplementation The new implementation contract address used for the upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyUpdater {
        require(newImplementation != address(0), Errors.ADDRESS_IS_ZERO);
        ++version;
    }
}