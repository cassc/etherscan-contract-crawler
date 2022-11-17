// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { Charge, Signature } from "../../../static/Structs.sol";

/**
 * @title  IDiagonalRegistry contract interface
 * @author Diagonal Finance
 */
interface IDiagonalRegistry {
    /// ****** Getters ******

    function owner() external view returns (address);

    function admin() external view returns (address);

    function orgBeacon() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string calldata);

    /// ****** Initialization ******

    function initialize(
        address _owner,
        address _admin,
        address _orgBeacon,
        address _orgImplementation
    ) external;

    /// ****** Organisation management ******

    function createOrganisation(bytes32 orgId, address orgSigner) external returns (address orgAddress);

    /// ****** Diagonal management ******

    function pause() external;

    function unpause() external;

    function updateDiagonalOwner(address newOwner) external;

    function updateDiagonalAdmin(address newAdmin) external;

    function updateDiagonalOrgBeacon(address newOrgBeacon) external;

    function updateDiagonalOrgImplementation(address newOrgImplementation) external;

    /// ******  View functions ******

    function getOrgAddress(bytes32 salt) external view returns (address orgAddress);
}