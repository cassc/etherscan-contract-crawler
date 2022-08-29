// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Used by the `NamedAddressSet` library to store sets of contracts
 */
interface INameIdentifier {
    /// @notice Should be implemented as a constant value
    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view returns (string memory);
}