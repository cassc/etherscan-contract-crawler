//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITimelockUpgradeable {
    /// @dev Emitted when a call is scheduled as part of operation `id`.
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /// @dev Emitted when a call is performed as part of operation `id`.
    event CallExecuted(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data
    );

    /// @dev Emitted when operation `id` is cancelled.
    event Cancelled(bytes32 indexed id);

    /// @dev Emitted when the minimum delay for future operations is modified.
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /// @dev Contract might receive/hold ETH as part of the maintenance process.
    receive() external payable;

    /// @notice Function for initializing the contract that can only be called once
    /// @param _accessControl The address of the access control contract
    /// @param _dao The address of the dao contract
    /// @param _minDelay init the contract with a given `minDelay`.
    function initialize(
        address _accessControl,
        address _dao,
        uint256 _minDelay
    ) external;

    /// @dev Changes the minimum timelock duration for future operations.
    /// Emits a {MinDelayChange} event.
    /// Requirements:
    /// - the caller must be authorized.
    /// @param newDelay Update the delay between queue and execute
    function updateDelay(uint256 newDelay) external;

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
    ) external;

    /// @dev Cancel an operation.
    /// - the caller must be authorized.
    /// @param id keccak256 hash of proposal params
    function cancel(bytes32 id) external;

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
    ) external payable;

    /// @dev Returns whether an id correspond to a registered operation. This
    /// includes both Pending, Ready and Done operations.
    /// @param id keccak256 hash of proposal params
    function isOperation(bytes32 id) external view returns (bool pending);

    /// @dev Returns whether an operation is pending or not.
    /// @param id keccak256 hash of proposal params
    function isOperationPending(bytes32 id)
        external
        view
        returns (bool pending);

    /// @dev Returns whether an operation is ready or not.
    /// @param id keccak256 hash of proposal params
    function isOperationReady(bytes32 id) external view returns (bool ready);

    /// @dev Returns whether an operation is done or not.
    /// @param id keccak256 hash of proposal params
    function isOperationDone(bytes32 id) external view returns (bool done);

    /// @dev Returns the timestamp at with an operation becomes ready (0 for
    /// unset operations, 1 for done operations).
    /// @param id keccak256 hash of proposal params
    function getTimestamp(bytes32 id) external view returns (uint256 timestamp);

    /// @dev Returns the minimum delay for an operation to become valid.
    /// This value can be changed by executing an operation that calls `updateDelay`.
    function getMinDelay() external view returns (uint256 duration);

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
    ) external pure returns (bytes32 hash);
}