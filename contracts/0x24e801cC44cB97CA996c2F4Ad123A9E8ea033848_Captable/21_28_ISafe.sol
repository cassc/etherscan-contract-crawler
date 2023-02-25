// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimum viable interface of a Safe that Firm's protocol needs
interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    receive() external payable;

    /**
     * @dev Allows modules to execute transactions
     * @notice Can only be called by an enabled module.
     * @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
     * @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
     */
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Returns if a certain address is an owner of this Safe
     * @return Whether the address is an owner or not
     */
    function isOwner(address owner) external view returns (bool);
}