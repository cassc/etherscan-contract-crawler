// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}