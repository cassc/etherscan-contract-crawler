pragma solidity ^0.8.10;

interface IExecutor {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a transaction is cancelled
    event CancelTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a transaction is executed
    event ExecuteTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a new delay value is set
    event NewDelay(uint256 indexed newDelay);
    /// @notice Emited when a transaction is queued
    event QueueTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function DELAY() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function cancelTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external;

    function executeTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes memory);

    function queueTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes32 txHash);

    function queuedTransactions(bytes32) external view returns (bool);
}