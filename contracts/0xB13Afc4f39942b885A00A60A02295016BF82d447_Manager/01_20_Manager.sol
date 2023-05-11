// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IVersionedContract } from "../utils/interfaces/IVersionedContract.sol";
import { VersionedContract } from "../VersionedContract.sol";
import { Ownable } from "../utils/Ownable.sol";
import { UUPS } from "../proxy/UUPS.sol";

import { Clones } from "../utils/Clones.sol";
import { IManager } from "./interfaces/IManager.sol";
import { IIntervals } from "../intervals/interfaces/IIntervals.sol";
import { IMilestones } from "../milestones/interfaces/IMilestones.sol";
import { IStream } from "../lib/interfaces/IStream.sol";

/// @title Manager
/// @author Matthew Harrison
/// @notice A contract to manage the creation of stream contracts
contract Manager is IManager, VersionedContract, UUPS, Ownable {
    /// @notice The milestones implementation address
    address public immutable msImpl;
    /// @notice The intervals implementation address
    address public immutable intvImpl;
    /// @notice The address of the botDAO
    address public immutable botDAO;
    /// @notice storage gap for future variables
    uint256[49] private __gap;

    constructor(address _msImpl, address _intvImpl, address _botDAO) initializer {
        msImpl = _msImpl;
        intvImpl = _intvImpl;
        botDAO = _botDAO;
    }

    /// @notice Initializes ownership of the manager contract
    /// @param _owner The owner address to set (will be transferred to the Builder DAO once its deployed)
    function initialize(address _owner) external initializer {
        /// Ensure an owner is specified
        if (_owner == address(0)) revert ADDRESS_ZERO();

        /// Set the contract owner
        __Ownable_init(_owner);
    }

    /// @notice Get the address for an interval stream
    /// @param   _owner      Contract owner
    /// @param   _startDate  Start date of the stream
    /// @param   _endDate    End date of the stream
    /// @param   _interval   Interval to issue payouts
    /// @param   _token      ERC20 token address
    /// @param   _recipient  Receiver of payouts
    function getIntvStreamAddress(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        address _token,
        address _recipient
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_owner, _startDate, _endDate, _interval, _token, _recipient));
        return Clones.predictDeterministicAddress(intvImpl, salt);
    }

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
    ) external returns (address) {
        IIntervals _stream = IIntervals(
            Clones.cloneDeterministic(intvImpl, keccak256(abi.encodePacked(_owner, _startDate, _endDate, _interval, _token, _recipient)))
        );
        _stream.initialize(_owner, uint64(_startDate), uint64(_endDate), uint32(_interval), uint96(_tip), _owed, _recipient, _token, botDAO);
        emit StreamCreated(address(_stream), "Intervals");

        return address(_stream);
    }

    /// @notice Get the address for a milestone stream
    /// @param   _msDates    Dates of milestones
    /// @param   _recipient   Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Deterministic address of the stream
    function getMSSStreamAddress(address _owner, uint64[] calldata _msDates, address _recipient, address _token) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_owner, _msDates, _token, _recipient));
        return Clones.predictDeterministicAddress(msImpl, salt);
    }

    /// @notice Get the address for an interval stream
    /// @param   _owner      Sender address
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
    ) external returns (address) {
        IMilestones _stream = IMilestones(Clones.cloneDeterministic(msImpl, keccak256(abi.encodePacked(_owner, _msDates, _token, _recipient))));
        _stream.initialize(_owner, _msPayments, _msDates, _tip, _recipient, _token, botDAO);

        emit StreamCreated(address(_stream), "Milestones");

        return address(_stream);
    }

    /// @notice A batch interface to release funds across multiple streams
    /// @param streams List of DAOStreams to call
    function batchRelease(address[] calldata streams) external {
        for (uint256 index = 0; index < streams.length; index++) {
            IStream(streams[index]).release();
        }
    }

    /// @notice Safely get the contract version of a target contract.
    /// @dev Assume `target` is a contract
    /// @return Contract version if found, empty string if not.
    function _safeGetVersion(address target) internal pure returns (string memory) {
        try IVersionedContract(target).contractVersion() returns (string memory version) {
            return version;
        } catch {
            return "";
        }
    }

    /// @notice Get current version of contract
    /// @param streamImpl Address of DAO version lookup
    function getStreamVersion(address streamImpl) external pure returns (string memory) {
        return _safeGetVersion(streamImpl);
    }

    /// @notice Ensures the caller is authorized to upgrade the contract
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}