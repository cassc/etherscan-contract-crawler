// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ISignedApprovalInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to be assigned an approver to sign transactions allowing mints.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface ISignedApprovalInitializer is IERC165 {

    /**
     * @notice Initializes approver.
     */
    function initializeSigner(address signer, uint256 maxQuantity) external;
}