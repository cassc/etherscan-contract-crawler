// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title  IDiagonalOrg contract interface
 * @author Diagonal Finance
 */
interface IDiagonalOrg {
    function initialize(address _signer) external;

    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string calldata);
}