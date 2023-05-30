// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title  IDiagonalOrgProxy contract interface
 * @author Diagonal Finance
 * @notice A DiagonalOrgProxy is a beacon proxy whose implementation
 *         is set in DiagonalOrgProxy.
 */
interface IDiagonalOrgProxy {
    /**
     * @dev Proxy initializer function. Necessary because we do not use constructors,
     * because of easier handling of deterministic deployments (create2).
     */
    function initializeProxy(
        address beacon,
        address implementation,
        bytes memory data
    ) external;
}