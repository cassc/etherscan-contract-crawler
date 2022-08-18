// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @title ERC165 Interface
/// @notice Interface of the ERC165 standard <https://eips.ethereum.org/EIPS/eip-165[EIP]>
/// @author Modified from openzeppelin-contracts <https://github.com/OpenZeppelin/openzeppelin-contracts>
interface IERC165 {
    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}