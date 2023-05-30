// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice define a set of error types

/**
 * @title Sealable
 * @author BaseLabs
 */
contract Sealable {
    error ErrContractSealed();
    event ContractSealed();

    /// @notice whether the contract is sealed
    bool public contractSealed;

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function _sealContract() internal {
        contractSealed = true;
        emit ContractSealed();
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier onlyNotSealed() {
        if (contractSealed) revert ErrContractSealed();
        _;
    }
}