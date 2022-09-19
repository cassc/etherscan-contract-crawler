// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Interface for managing creator approvals
 */
interface ICreatorApproval {
    function isApprovedCreator(address account) external view returns (bool);
}