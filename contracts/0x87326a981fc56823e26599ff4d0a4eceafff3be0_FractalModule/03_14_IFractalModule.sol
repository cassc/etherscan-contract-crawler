//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * A specification for a Safe module contract that allows for a "parent-child"
 * DAO relationship.
 *
 * Adding the module should allow for a designated set of addresses to execute
 * transactions on the Safe, which in our implementation is the set of parent
 * DAOs.
 */
interface IFractalModule {

    /**
     * Allows an authorized address to execute arbitrary transactions on the Safe.
     *
     * @param execTxData data of the transaction to execute
     */
    function execTx(bytes memory execTxData) external;

    /**
     * Adds `_controllers` to the list of controllers, which are allowed
     * to execute transactions on the Safe.
     *
     * @param _controllers addresses to add to the contoller list
     */
    function addControllers(address[] memory _controllers) external;

    /**
     * Removes `_controllers` from the list of controllers.
     *
     * @param _controllers addresses to remove from the controller list
     */
    function removeControllers(address[] memory _controllers) external;
}