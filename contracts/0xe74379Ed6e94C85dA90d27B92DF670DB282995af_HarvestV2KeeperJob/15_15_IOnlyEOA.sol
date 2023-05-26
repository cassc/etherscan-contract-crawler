// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IOnlyEOA {
    // Events

    /// @notice Emitted when onlyEOA is set
    event OnlyEOASet(bool _onlyEOA);

    // Errors

    /// @notice Throws when keeper is not tx.origin
    error OnlyEOA();

    // Views

    /// @return _onlyEOA Whether the keeper is required to be an EOA or not
    function onlyEOA() external returns (bool _onlyEOA);

    // Methods

    /// @notice Allows governor to set the onlyEOA condition
    /// @param _onlyEOA Whether the keeper is required to be an EOA or not
    function setOnlyEOA(bool _onlyEOA) external;
}