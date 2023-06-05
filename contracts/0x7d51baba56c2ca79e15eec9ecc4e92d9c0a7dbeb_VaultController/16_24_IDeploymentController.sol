// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ICloneFactory } from "./ICloneFactory.sol";
import { ICloneRegistry } from "./ICloneRegistry.sol";
import { IPermissionRegistry } from "./IPermissionRegistry.sol";
import { ITemplateRegistry, Template } from "./ITemplateRegistry.sol";

interface IDeploymentController is ICloneFactory, ICloneRegistry {
  function templateCategoryExists(bytes32 templateCategory) external view returns (bool);

  function templateExists(bytes32 templateId) external view returns (bool);

  function addTemplate(
    bytes32 templateCategory,
    bytes32 templateId,
    Template memory template
  ) external;

  function addTemplateCategory(bytes32 templateCategory) external;

  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external;

  function getTemplate(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory);

  function nominateNewDependencyOwner(address _owner) external;

  function acceptDependencyOwnership() external;

  function cloneFactory() external view returns (ICloneFactory);

  function cloneRegistry() external view returns (ICloneRegistry);

  function templateRegistry() external view returns (ITemplateRegistry);

  function PermissionRegistry() external view returns (IPermissionRegistry);

  function addClone(address clone) external;
}