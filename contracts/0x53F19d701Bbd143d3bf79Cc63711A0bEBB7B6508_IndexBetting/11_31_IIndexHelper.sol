// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index hepler interface
/// @notice Interface containing index utils methods
interface IIndexHelper {
    /// @notice Returns index related info
    /// @param _index Address of index
    /// @return _valueInBase Index's evaluation in base asset
    /// @return _totalSupply Index's total supply
    function totalEvaluation(address _index) external view returns (uint256 _valueInBase, uint256 _totalSupply);
}