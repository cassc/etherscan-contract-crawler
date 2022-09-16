// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Name registry interface
/// @notice Providing information about index names and symbols
interface INameRegistry {
    event SetName(address index, string name);
    event SetSymbol(address index, string name);

    /// @notice Sets name of the given index
    /// @param _index Index address
    /// @param _name New index name
    function setIndexName(address _index, string calldata _name) external;

    /// @notice Sets symbol for the given index
    /// @param _index Index address
    /// @param _symbol New index symbol
    function setIndexSymbol(address _index, string calldata _symbol) external;

    /// @notice Returns index address by name
    /// @param _name Index name to look for
    /// @return Index address
    function indexOfName(string calldata _name) external view returns (address);

    /// @notice Returns index address by symbol
    /// @param _symbol Index symbol to look for
    /// @return Index address
    function indexOfSymbol(string calldata _symbol) external view returns (address);

    /// @notice Returns name of the given index
    /// @param _index Index address
    /// @return Index name
    function nameOfIndex(address _index) external view returns (string memory);

    /// @notice Returns symbol of the given index
    /// @param _index Index address
    /// @return Index symbol
    function symbolOfIndex(address _index) external view returns (string memory);
}