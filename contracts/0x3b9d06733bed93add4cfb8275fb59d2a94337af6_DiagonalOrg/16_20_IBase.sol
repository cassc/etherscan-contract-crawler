// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title  IBase contract interface
 * @author Diagonal Finance
 * @notice Module used as a base for organization smart contract modules
 */
interface IBase {
    function signer() external view returns (address);

    function operationIds(bytes32) external view returns (bool);

    function isBot(address bot) external view returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function DIAGONAL_ADMIN() external view returns (address);
}