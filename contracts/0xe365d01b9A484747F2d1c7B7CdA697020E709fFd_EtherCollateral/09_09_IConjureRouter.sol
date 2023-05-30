// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureRouter
/// @notice Interface for interacting with the ConjureRouter Contract
interface IConjureRouter {

    /**
     * @dev calls the deposit function
    */
    function deposit() external payable;
}