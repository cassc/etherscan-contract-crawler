//SPDX-License-Identifier: Unlicense
// OpenZeppelin Contracts v4.4.1 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "@fractal-framework/core-contracts/contracts/ModuleBase.sol";
import "@fractal-framework/core-contracts/contracts/interfaces/IDAO.sol";
import "../interfaces/ITimelockUpgradeable.sol";

/// @dev Contract module which acts as a timelocked controller. When set as the
/// executor for the DAO execute action, it enforces a timelock on all
/// DAO executions initiated by the governor contract. This gives time for users of the
/// controlled contract to exit before a potentially dangerous maintenance
/// operation is applied.
contract TimelockUpgradeable is ModuleBase, ITimelockUpgradeable {
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 public minDelay;
    IDAO public dao;

    /// @dev Contract might receive/hold ETH as part of the maintenance process.
    receive() external payable {}

    /// @notice Function for initializing the contract that can only be called once
    /// @param _accessControl The address of the access control contract
    /// @param _dao The address of the dao contract
    /// @param _minDelay init the contract with a given `minDelay`.
    function initialize(
        address _accessControl,
        address _dao,
        uint256 _minDelay
    ) external initializer {
        __initBase(_accessControl, msg.sender, "Timelock Module");
        dao = IDAO(_dao);
        minDelay = _minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /// @dev Changes the minimum timelock duration for future operations.
    /// Emits a {MinDelayChange} event.
    /// Requirements:
    /// - the caller must be authorized.
    /// @param newDelay Update the delay between queue and execute
    function updateDelay(uint256 newDelay) external virtual authorized {
        require(
            msg.sender == address(this),
            "TimelockController: caller must be timelock"
        );
        emit MinDelayChange(minDelay, newDelay);
        minDelay = newDelay;
    }

    /// @dev Schedule an operation containing a batch of transactions.
    /// Emits one {CallScheduled} event per transaction in the batch.
    /// - the caller must be authorized.
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param datas Function Sigs w/ Params 
    /// @param predecessor GovTimelock passes this as 0
    /// @param salt Description Hash
    /// @param delay current delay set in contract
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external virtual authorized {
        require(
            targets.length == values.length,
            "TimelockController: length mismatch"
        );
        require(
            targets.length == datas.length,
            "TimelockController: length mismatch"
        );

        bytes32 id = hashOperationBatch(
            targets,
            values,
            datas,
            predecessor,
            salt
        );
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(
                id,
                i,
                targets[i],
                values[i],
                datas[i],
                predecessor,
                delay
            );
        }
    }

    /// @dev Cancel an operation.
    /// - the caller must be authorized.
    /// @param id keccak256 hash of proposal params
    function cancel(bytes32 id) external virtual authorized {
        require(
            isOperationPending(id),
            "TimelockController: operation cannot be cancelled"
        );
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /// @dev Execute an (ready) operation containing a batch of transactions.
    /// Emits one {CallExecuted} event per transaction in the batch.
    /// - the caller must be authorized
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param datas Function Sigs w/ Params 
    /// @param predecessor GovTimelock passes this as 0
    /// @param salt Description Hash
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) external payable virtual authorized {
        require(
            targets.length == values.length,
            "TimelockController: length mismatch"
        );
        require(
            targets.length == datas.length,
            "TimelockController: length mismatch"
        );

        bytes32 id = hashOperationBatch(
            targets,
            values,
            datas,
            predecessor,
            salt
        );
        _beforeCall(id, predecessor);
        dao.execute(targets, values, datas);
        _afterCall(id);
    }

    /// @dev Returns whether an id correspond to a registered operation. This
    /// includes both Pending, Ready and Done operations.
    /// @param id keccak256 hash of proposal params
    function isOperation(bytes32 id)
        public
        view
        virtual
        returns (bool pending)
    {
        return getTimestamp(id) > 0;
    }

    /// @dev Returns whether an operation is pending or not.
    /// @param id keccak256 hash of proposal params
    function isOperationPending(bytes32 id)
        public
        view
        virtual
        returns (bool pending)
    {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /// @dev Returns whether an operation is ready or not.
    /// @param id keccak256 hash of proposal params
    function isOperationReady(bytes32 id)
        public
        view
        virtual
        returns (bool ready)
    {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /// @dev Returns whether an operation is done or not.
    /// @param id keccak256 hash of proposal params
    function isOperationDone(bytes32 id)
        public
        view
        virtual
        returns (bool done)
    {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /// @dev Returns the timestamp at with an operation becomes ready (0 for
    /// unset operations, 1 for done operations).
    /// @param id keccak256 hash of proposal params
    function getTimestamp(bytes32 id)
        public
        view
        virtual
        returns (uint256 timestamp)
    {
        return _timestamps[id];
    }

    /// @dev Returns the minimum delay for an operation to become valid.
    /// This value can be changed by executing an operation that calls `updateDelay`.
    function getMinDelay() public view virtual returns (uint256 duration) {
        return minDelay;
    }

    /// @dev Returns the identifier of an operation containing a batch of
    /// transactions.
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param datas Function Sigs w/ Params 
    /// @param predecessor GovTimelock passes this as 0
    /// @param salt Description Hash
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /// @dev Schedule an operation that is to becomes valid after a given delay.
    /// @param id keccak256 hash of proposal params
    /// @param delay current delay set in contract
    function _schedule(bytes32 id, uint256 delay) private {
        require(
            !isOperation(id),
            "TimelockController: operation already scheduled"
        );
        require(
            delay >= getMinDelay(),
            "TimelockController: insufficient delay"
        );
        _timestamps[id] = block.timestamp + delay;
    }

    /// @dev Checks before execution of an operation's calls.
    /// @param id keccak256 hash of proposal params
    /// @param predecessor GovTimelock passes this as 0
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(
            isOperationReady(id),
            "TimelockController: operation is not ready"
        );
        require(
            predecessor == bytes32(0) || isOperationDone(predecessor),
            "TimelockController: missing dependency"
        );
    }

    /// @dev Checks after execution of an operation's calls.
    /// @param id keccak256 hash of proposal params
    function _afterCall(bytes32 id) private {
        require(
            isOperationReady(id),
            "TimelockController: operation is not ready"
        );
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /// @dev Execute an operation's call.
    /// Emits a {CallExecuted} event.
    /// @param id keccak256 hash of proposal params
    /// @param index current index of call
    /// @param target Contract address the DAO will call
    /// @param value Ether value to be sent to the target address
    /// @param data Function Sig w/ Params 
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[48] private __gap;
}