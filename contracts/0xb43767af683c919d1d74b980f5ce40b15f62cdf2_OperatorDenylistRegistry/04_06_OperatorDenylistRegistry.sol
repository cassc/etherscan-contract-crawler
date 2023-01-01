// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC173} from "./interfaces/IERC173.sol";
import {IOperatorDenylistRegistry} from "./interfaces/IOperatorDenylistRegistry.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title Operator Denylist Registry
/// @author Kfish
/// @dev We use denied as default instead of approved because it defaults to false,
///      otherwise we would have to approve operators instead which serves another purpose
/// @notice This is a registry to be used by creators where they can deny operators from
///         interacting with their contracts
contract OperatorDenylistRegistry is IOperatorDenylistRegistry {
    /// @notice Used to check administrator rights using IAccessControl
    bytes32 private constant _DEFAULT_ADMIN_ROLE = 0x00;

    struct OperatedContract {
        mapping(address => bool) operators;
        mapping(address => bool) registryOperators;
    }

    /// @notice Mapping of a contract address to an OperatedContract struct
    mapping(address => OperatedContract) private operatedContracts;
    /// @notice Mapping of a contract address to it's codehash
    ///         used to keep track of new address registrations
    mapping(address => bytes32) private codeHashes;

    /// @notice Add or remove a batch of addresses to the registry
    /// @dev Calls setOperatorDenied for each entry
    /// @param operatedContract the contract being managed
    /// @param operators list of addresses to update their denial state
    /// @param denials whether each operator should be denied or not
    function batchSetOperatorDenied(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata denials
    ) external {
        if (operators.length == 0) revert InvalidOperators();
        if (operators.length != denials.length)
            revert OperatorsDenialsLengthMismatch();
        for (uint256 i = 0; i < operators.length; i++) {
            setOperatorDenied(operatedContract, operators[i], denials[i]);
        }
    }

    /// @notice Add registry operators for a managed contract
    /// @dev Calls setApprovalForRegistryOperator
    /// @param operatedContract the contract being managed
    /// @param operators list of addresses to update as operators
    /// @param approvals whether each operator is approved or not
    function batchSetApprovalForRegistryOperator(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata approvals
    ) external {
        if (operators.length == 0) revert InvalidOperators();
        if (operators.length != approvals.length)
            revert OperatorsApprovalsLengthMismatch();
        for (uint256 i = 0; i < operators.length; i++) {
            setApprovalForRegistryOperator(
                operatedContract,
                operators[i],
                approvals[i]
            );
        }
    }

    /// @notice Add a registry operator for a managed contract
    /// @dev Operators will be able to add or remove operators
    ///      and add or remove entries in the managed contract's denylist
    /// @param operatedContract the contract being managed
    /// @param operator the address of the registry operator
    /// @param approved whether the registry operator will be approved or not
    function setApprovalForRegistryOperator(
        address operatedContract,
        address operator,
        bool approved
    ) public {
        if (operatedContract == address(0) || operator == address(0))
            revert AddressZero();
        if (
            !_hasOperatedContractPrivileges(operatedContract, msg.sender) &&
            !isRegistryOperatorApproved(operatedContract, msg.sender)
        ) revert SenderNotContractOwnerOrRegistryOperator();
        operatedContracts[operatedContract].registryOperators[
            operator
        ] = approved;

        emit ApprovedRegistryOperator(
            msg.sender,
            operatedContract,
            operator,
            approved
        );
    }

    /// @notice Setting an operator as denied or not
    /// @param operatedContract the contract being managed
    /// @param operator the operator being updated
    /// @param denied whether the operator is denied or not
    function setOperatorDenied(
        address operatedContract,
        address operator,
        bool denied
    ) public {
        if (operatedContract == address(0) || operator == address(0))
            revert AddressZero();
        if (
            !_hasOperatedContractPrivileges(operatedContract, msg.sender) &&
            !isRegistryOperatorApproved(operatedContract, msg.sender)
        ) revert SenderNotContractOwnerOrRegistryOperator();
        bytes32 operatorCodeHash = operatedContract.codehash;
        operatedContracts[operatedContract].operators[operator] = denied;
        emit DeniedOperator(msg.sender, operatedContract, operator, denied);

        if (codeHashes[operator] != operatorCodeHash) {
            codeHashes[operator] = operatorCodeHash;
            emit RegisteredNewOperator(msg.sender, operator, operatorCodeHash);
        }
    }

    /// @notice Checks whether an operator is denied or not
    /// @param operatedContract the contract being managed
    /// @param operator the operator to check
    /// @return true if the operator is denied
    function isOperatorDenied(address operatedContract, address operator)
        public
        view
        returns (bool)
    {
        if (operatedContract == address(0)) revert AddressZero();
        if (operatedContract.code.length == 0) revert InvalidContractAddress();
        if (operator.code.length > 0) {
            return operatedContracts[operatedContract].operators[operator];
        } else {
            return false;
        }
    }

    /// @notice Checks whether an operator is denied or not for msg.sender
    /// @dev To be called by contracts using the registry
    /// @param operator the operator to check for
    /// @return true if the operator is denied
    function isOperatorDenied(address operator) public view returns (bool) {
        return isOperatorDenied(msg.sender, operator);
    }

    /// @notice Check whether an address is approved to update a contracts denylist
    /// @param operatedContract the contract being managed
    /// @param operator the registry operator to check
    /// @return true if the registry operator is approved
    function isRegistryOperatorApproved(
        address operatedContract,
        address operator
    ) public view returns (bool) {
        if (operatedContract == address(0) || operator == address(0))
            revert AddressZero();
        return
            _hasOperatedContractPrivileges(operatedContract, operator) ||
            operatedContracts[operatedContract].registryOperators[operator];
    }

    /// @notice Checks whether an operator is owner or has DEFAULT_ADMIN_ROLE
    /// @param operatedContract the contract being managed
    /// @param operator the operator to check
    /// @return true if the operator is owner or admin of the operated contract
    function _hasOperatedContractPrivileges(
        address operatedContract,
        address operator
    ) private view returns (bool) {
        if (operatedContract.code.length == 0) revert InvalidContractAddress();
        if (
            ERC165Checker.supportsInterface(
                operatedContract,
                type(IAccessControl).interfaceId
            )
        ) {
            return _isDefaultAdminOfContract(operatedContract, operator);
        }
        if (
            ERC165Checker.supportsInterface(
                operatedContract,
                type(IERC173).interfaceId
            )
        ) {
            return IERC173(operatedContract).owner() == operator;
        } else {
            try IERC173(operatedContract).owner() returns (
                address contractOwner
            ) {
                return contractOwner == operator;
            } catch {
                revert IOperatorDenylistRegistry.CannotVerifyContractOwnership();
            }
        }
    }

    /// @notice Check whether an operator has the DEFAULT_ADMIN_ROLE of a contract
    /// @dev called by _hasOperatedContractPrivileges only if the AccessControl interface
    ///      is supported
    /// @param operatedContract the contract being managed
    /// @param operator the address to check
    function _isDefaultAdminOfContract(
        address operatedContract,
        address operator
    ) private view returns (bool) {
        if (operatedContract.code.length == 0) revert InvalidContractAddress();
        return
            IAccessControl(operatedContract).hasRole(
                _DEFAULT_ADMIN_ROLE,
                operator
            );
    }
}