// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOperatorDenylistRegistry {
    error InvalidContractAddress();
    error SenderNotContractOwnerOrRegistryOperator();
    error CannotVerifyContractOwnership();
    error AddressZero();
    error OperatorsApprovalsLengthMismatch();
    error OperatorsDenialsLengthMismatch();
    error InvalidOperators();

    event RegisteredNewOperator(
        address indexed sender,
        address indexed operator,
        bytes32 codeHash
    );
    event DeniedOperator(
        address indexed sender,
        address indexed operatedContract,
        address indexed operator,
        bool denied
    );
    event ApprovedRegistryOperator(
        address indexed sender,
        address indexed operatedContract,
        address indexed operator,
        bool approved
    );

    function isRegistryOperatorApproved(
        address operatedContract,
        address operator
    ) external view returns (bool);

    function isOperatorDenied(address operator) external view returns (bool);

    function isOperatorDenied(address operatedContract, address operator)
        external
        view
        returns (bool);

    function setOperatorDenied(
        address operatedContract,
        address operator,
        bool denied
    ) external;

    function setApprovalForRegistryOperator(
        address operatedContract,
        address operator,
        bool approved
    ) external;

    function batchSetApprovalForRegistryOperator(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata approvals
    ) external;

    function batchSetOperatorDenied(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata denials
    ) external;
}