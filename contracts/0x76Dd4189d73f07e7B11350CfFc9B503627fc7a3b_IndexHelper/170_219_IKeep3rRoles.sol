// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rRoles contract
/// @notice Manages the Keep3r specific roles
interface IKeep3rRoles {
    // Events

    /// @notice Emitted when a slasher is added
    /// @param _slasher Address of the added slasher
    event SlasherAdded(address _slasher);

    /// @notice Emitted when a slasher is removed
    /// @param _slasher Address of the removed slasher
    event SlasherRemoved(address _slasher);

    /// @notice Emitted when a disputer is added
    /// @param _disputer Address of the added disputer
    event DisputerAdded(address _disputer);

    /// @notice Emitted when a disputer is removed
    /// @param _disputer Address of the removed disputer
    event DisputerRemoved(address _disputer);

    // Variables

    /// @notice Maps an address to a boolean to determine whether the address is a slasher or not.
    /// @return _isSlasher Whether the address is a slasher or not
    function slashers(address _slasher) external view returns (bool _isSlasher);

    /// @notice Maps an address to a boolean to determine whether the address is a disputer or not.
    /// @return _isDisputer Whether the address is a disputer or not
    function disputers(address _disputer) external view returns (bool _isDisputer);

    // Errors

    /// @notice Throws if the address is already a registered slasher
    error SlasherExistent();

    /// @notice Throws if caller is not a registered slasher
    error SlasherUnexistent();

    /// @notice Throws if the address is already a registered disputer
    error DisputerExistent();

    /// @notice Throws if caller is not a registered disputer
    error DisputerUnexistent();

    /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
    error OnlySlasher();

    /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
    error OnlyDisputer();

    // Methods

    /// @notice Registers a slasher by updating the slashers mapping
    function addSlasher(address _slasher) external;

    /// @notice Removes a slasher by updating the slashers mapping
    function removeSlasher(address _slasher) external;

    /// @notice Registers a disputer by updating the disputers mapping
    function addDisputer(address _disputer) external;

    /// @notice Removes a disputer by updating the disputers mapping
    function removeDisputer(address _disputer) external;
}