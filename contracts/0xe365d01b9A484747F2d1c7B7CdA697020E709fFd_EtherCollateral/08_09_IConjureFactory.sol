// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureFactory
/// @notice Interface for interacting with the ConjureFactory Contract
interface IConjureFactory {

    /**
     * @dev gets the current conjure router
     *
     * @return the current conjure router
    */
    function getConjureRouter() external returns (address payable);
}