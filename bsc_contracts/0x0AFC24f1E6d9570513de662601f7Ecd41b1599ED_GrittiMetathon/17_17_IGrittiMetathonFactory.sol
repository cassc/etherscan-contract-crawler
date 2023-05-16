// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title The interface for the Gritti Metathon Factory
/// @notice The Gritti Metathon Factory facilitates creation of Gritti Metathon events
interface IGrittiMetathonFactory {
    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Emitted when a event is created
    /// @param addr The address of the created event
    event EventCreated(string eventSlug, address indexed addr);

    /// @notice Returns the event address for a given event slug, or address 0 if it does not exist
    /// @return addr The pool address
    function getEvent(string memory eventSlug) external view returns (address addr);

    /**
     * @dev Returns the total count of events stored by the contract.
     */
    function countEvent() external view returns (uint256 count);

    /**
     * @dev Returns a event slug at a given `index` of all the events stored by the contract.
     * Use along with {countEvent} to enumerate all events.
     */
    function eventByIndex(uint256 index) external view returns (string memory eventSlug);

    /**
     * @dev Returns a event address at a given `index` of all the events stored by the contract.
     * Use along with {countEvent} to enumerate all events.
     */
    function eventAddrByIndex(uint256 index) external view returns (address eventAddr);

    /// @notice Creates a event for the given event slug
    /// @return addr The address of the newly created event
    function createEvent(
        string memory eventSlug,
        uint256 maxSupply,
        string memory eventName,
        string memory rootHash,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) external returns (address addr);
}