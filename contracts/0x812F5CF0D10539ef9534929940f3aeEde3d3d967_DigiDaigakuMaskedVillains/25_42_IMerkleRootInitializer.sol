// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IMerkleRootInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include a merkle root.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IMerkleRootInitializer is IERC165 {

    /**
     * @notice Initializes root collection parameters
     */
    function initializeMerkleRoot(bytes32 merkleRoot_) external;
}