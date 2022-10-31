// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: inheriting from modified Governor

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

import { IGovernor } from "./IGovernor.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelock is IGovernor {
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
}