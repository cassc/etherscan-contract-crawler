/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/ITaskExecutor.sol";
import "./abstract/task-manager/AdminTaskManaged.sol";
import "./abstract/task-manager/CreatorRoleEnabled.sol";
import "./abstract/task-manager/ApproverRoleEnabled.sol";
import "./abstract/task-manager/ExecutorRoleEnabled.sol";
import "./abstract/task-manager/FinalizerRoleEnabled.sol";
import "./abstract/task-manager/ETHVaultEnabled.sol";
import "./abstract/task-manager/ERC20VaultEnabled.sol";
import "./abstract/task-manager/ERC721VaultEnabled.sol";
import "./abstract/task-manager/ERC1155VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskManager is
  ITaskExecutor,
  AdminTaskManaged,
  CreatorRoleEnabled,
  ApproverRoleEnabled,
  ExecutorRoleEnabled,
  FinalizerRoleEnabled,
  ETHVaultEnabled,
  ERC20VaultEnabled,
  ERC721VaultEnabled,
  ERC1155VaultEnabled,
  ERC165
{
    modifier onlyPrivileged() {
        require(
            _isAdmin(msg.sender) ||
            _isCreator(msg.sender) ||
            _isApprover(msg.sender) ||
            _isExecutor(msg.sender),
            "TaskManager: not a privileged account"
        );
        _;
    }

    constructor(
      address[] memory initialAdmins,
      address[] memory initialCreators,
      address[] memory initialApprovers,
      address[] memory initialExecutors,
      bool enableDeposit
    ) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TaskManager: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        require(initialCreators.length >= 1, "TaskManager: not enough initial creators");
        for (uint i = 0; i < initialCreators.length; i++) {
            _addCreator(initialCreators[i]);
        }
        require(initialApprovers.length >= 3, "TaskManager: not enough initial approvers");
        for (uint i = 0; i < initialApprovers.length; i++) {
            _addApprover(initialApprovers[i]);
        }
        require(initialExecutors.length >= 1, "TaskManager: not enough initial executors");
        for (uint i = 0; i < initialExecutors.length; i++) {
            _addExecutor(initialExecutors[i]);
        }
        _setEnableDeposit(enableDeposit);
    }

    function supportsInterface(bytes4 interfaceId)
      public view virtual override(ERC1155Vault, ERC165) returns (bool)
    {
        return interfaceId == type(ITaskExecutor).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId;
    }

    function stats() external view onlyAdmin returns (uint, uint, uint, uint, uint) {
        return (_nrOfAdmins, _nrOfCreators, _nrOfApprovers, _nrOfExecutors, _nrOfFinalizers);
    }

    function isFinalized(uint256 taskId) external view
      onlyPrivileged
      taskMustExist(taskId)
      returns (bool)
    {
        if (_isTaskAdministrative(taskId)) {
            require(_isAdmin(msg.sender), "TaskManager: not an admin account");
        }
        return _isTaskFinalized(taskId);
    }

    function getTaskURI(uint256 taskId) external view
      onlyPrivileged
      taskMustExist(taskId)
      returns (string memory)
    {
        if (_isTaskAdministrative(taskId)) {
            require(_isAdmin(msg.sender), "TaskManager: not an admin account");
        }
        return _getTaskURI(taskId);
    }

    function getNrOfApprovals(uint256 taskId) external view
      onlyPrivileged
      taskMustExist(taskId)
      returns (uint)
    {
        if (_isTaskAdministrative(taskId)) {
            require(_isAdmin(msg.sender), "TaskManager: not an admin account");
        }
        return _getTaskNrApprovals(taskId);
    }

    function createTask(string memory taskURI) external
      onlyCreator
    {
        _createTask(taskURI, false);
    }

    function finalizeTask(uint256 taskId, string memory reason) external
      onlyCreatorOrAdmin
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _finalizeTask(taskId, reason);
    }

    function approveTask(uint256 taskId) external
      onlyApprover
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _approveTask(msg.sender, taskId);
    }

    function withdrawTaskApproval(uint256 taskId) external
      onlyApprover
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _withdrawTaskApproval(msg.sender, taskId);
    }

    function executeTask(address origin, uint256 taskId) external virtual override
      onlyFinalizer
      mustBeExecutor(origin)
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustBeApproved(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _finalizeTask(taskId, "");
        emit TaskExecuted(msg.sender, origin, taskId);
    }

    function executeAdminTask(address origin, uint256 taskId) external virtual override
      onlyFinalizer
      mustBeExecutor(origin)
      taskMustExist(taskId)
      taskMustBeAdministrative(taskId)
      taskMustBeApproved(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _finalizeTask(taskId, "");
        emit TaskExecuted(msg.sender, origin, taskId);
    }

    function _getRequiredNrApprovals(uint256 taskId)
      internal view virtual override(AdminTaskManaged, TaskManaged) returns (uint) {
        require(_taskExists(taskId), "TaskManager: task does not exist");
        if (_isTaskAdministrative(taskId)) {
            return (1 + _nrOfAdmins / 2);
        } else {
            return (1 + _nrOfApprovers / 2);
        }
    }

    receive() external payable {
        require(_isDepositEnabled(), "TaskManager: cannot accept ether");
    }

    fallback() external payable {
        revert("TaskManager: fallback always fails");
    }
}