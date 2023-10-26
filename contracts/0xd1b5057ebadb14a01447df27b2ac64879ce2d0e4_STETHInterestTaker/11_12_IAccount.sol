// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IAccount {
    function execTransaction(CallData calldata callData) external returns (TransactionResult memory result);

    function execTransactions(
        CallData[] calldata callDataList
    ) external returns (TransactionResult[] memory resultList);

    function setAuthorizer(address _authorizer) external;

    function setRoleManager(address _roleManager) external;

    function addDelegate(address _delegate) external;

    function addDelegates(address[] calldata _delegates) external;

    /// @dev Sub instance should override this to set `from` for transaction
    /// @return account The address for the contract wallet, also the
    ///         `msg.sender` address which send the transaction.
    function getAccountAddress() external view returns (address account);

    function roleManager() external view returns (address _roleManager);

    function authorizer() external view returns (address _authorizer);
}