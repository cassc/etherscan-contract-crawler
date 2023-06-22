// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title An extension that enables the contract owner to set and update the date of a presale.
abstract contract WithPresaleStart is Ownable
{
    // Stores the presale start time
    uint256 private _presaleStart;

    /// @dev Emitted when the presale start date changes
    event PresaleStartChanged(uint256 time);

    /// @dev Initialize with a given timestamp when to start the presale
    constructor (uint256 time) {
        _presaleStart = time;
    }

    /// @dev Sets the start of the presale. Only owners can do so.
    function setPresaleStart(uint256 time) public virtual onlyOwner beforePresaleStart {
        _presaleStart = time;
        emit PresaleStartChanged(time);
    }

    /// @dev Returns the start of the presale in seconds since the Unix Epoch
    function presaleStart() public view virtual returns (uint256) {
        return _presaleStart;
    }

    /// @dev Returns true if the presale has started
    function presaleStarted() public view virtual returns (bool) {
        return _presaleStart <= block.timestamp;
    }

    /// @dev Modifier to make a function callable only after presale start
    modifier afterPresaleStart() {
        require(presaleStarted(), "Presale hasn't started yet");
        _;
    }

    /// @dev Modifier to make a function callable only before presale start
    modifier beforePresaleStart() {
        require(! presaleStarted(), "Presale has already started");
        _;
    }
}