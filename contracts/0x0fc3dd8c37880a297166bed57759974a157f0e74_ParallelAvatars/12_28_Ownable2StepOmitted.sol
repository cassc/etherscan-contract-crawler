// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @dev Contract module which omits the ability to renounce ownership
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable2Step).
 */
abstract contract Ownable2StepOmitted is Ownable2Step {
    /**
     * @dev Omit the ability to renounce ownership
     *
     */
    function renounceOwnership() public virtual override onlyOwner {}
}