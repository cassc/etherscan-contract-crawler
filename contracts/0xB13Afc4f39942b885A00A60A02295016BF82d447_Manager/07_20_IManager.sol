// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IManger
/// @author Matthew Harrison
/// @notice The Manager interface
interface IManager {
    /// @notice The address of the Milestones implementation
    function msImpl() external view returns (address);

    /// @notice The address of the Intervals implementation
    function intvImpl() external view returns (address);

    /// @notice Emits stream created event
    /// @param streamId, logs id for stream
    event StreamCreated(address streamId, string streamType);

    /// @notice A batch interface to release funds across multiple streams
    /// @param streams List of streams to distribute funds from
    function batchRelease(address[] calldata streams) external;

    /// @notice Get current version of contract
    /// @param daoStream Address of DAO version lookup
    function getStreamVersion(address daoStream) external pure returns (string memory);

    /// @notice Get the address for an interval stream
    /// @param   _owner      The owner of the stream
    /// @param   _msPayments Milestones payments array
    /// @param   _msDates    Milestones date array
    /// @param   _tip        Chosen percentage allocated to bots who disburse funds
    /// @param   _recipient  Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Address of the stream
    function createMSStream(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token
    ) external returns (address);

    /// @notice Creates a stream
    /// @param _owner The owner of the stream
    /// @param _startDate Start date for stream
    /// @param _endDate End date for stream
    /// @param _interval The frequency at which the funds are being released
    /// @param _owed How much is owed to the stream recipient
    /// @param _tip Chosen percentage allocated to bots who disburse funds
    /// @param _recipient Account which receives disbursed funds
    /// @param _token Token address
    /// @return address The address of the stream
    function createIntvStream(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        uint256 _owed,
        uint256 _tip,
        address _recipient,
        address _token
    ) external returns (address);

    /// @notice Get the address for a milestone stream
    /// @param   _owner      Contract owner
    /// @param   _msDates    Dates of milestones
    /// @param   _recipient   Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Address of the stream
    function getMSSStreamAddress(address _owner, uint64[] calldata _msDates, address _recipient, address _token) external view returns (address);

    /// @notice Get the address for an interval stream
    /// @param   _owner      Contract owner
    /// @param   _startDate  Start date of the stream
    /// @param   _endDate    End date of the stream
    /// @param   _interval   Interval to issue payouts
    /// @param   _token      ERC20 token address
    /// @param   _recipient  Receiver of payouts
    /// @return  address     Address of the stream
    function getIntvStreamAddress(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        address _token,
        address _recipient
    ) external view returns (address);
}