// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Owned } from "../utils/Owned.sol";
import { IOwned } from "../interfaces/IOwned.sol";
import { ICloneFactory } from "../interfaces/vault/ICloneFactory.sol";
import { ICloneRegistry } from "../interfaces/vault/ICloneRegistry.sol";
import { ITemplateRegistry, Template } from "../interfaces/vault/ITemplateRegistry.sol";

/**
 * @title   DeploymentController
 * @author  RedVeil
 * @notice  Bundles contracts for creating and registering clones.
 * @dev     Allows interacting with them via a single transaction.
 */
contract DeploymentController is Owned {
  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  ICloneFactory public cloneFactory;
  ICloneRegistry public cloneRegistry;
  ITemplateRegistry public templateRegistry;

  /**
   * @notice Creates `DeploymentController`
   * @param _owner `AdminProxy`
   * @param _cloneFactory Creates clones.
   * @param _cloneRegistry Keeps track of new clones.
   * @param _templateRegistry Registry of templates used for deployments.
   * @dev Needs to call `acceptDependencyOwnership()` after the deployment.
   */
  constructor(
    address _owner,
    ICloneFactory _cloneFactory,
    ICloneRegistry _cloneRegistry,
    ITemplateRegistry _templateRegistry
  ) Owned(_owner) {
    cloneFactory = _cloneFactory;
    cloneRegistry = _cloneRegistry;
    templateRegistry = _templateRegistry;
  }

  /*//////////////////////////////////////////////////////////////
                          TEMPLATE LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Adds a new category for templates. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param templateCategory A new template category.
   * @dev (See TemplateRegistry for more details)
   */
  function addTemplateCategory(bytes32 templateCategory) external onlyOwner {
    templateRegistry.addTemplateCategory(templateCategory);
  }

  /**
   * @notice Adds a new category for templates.
   * @param templateCategory Category of the new template.
   * @param templateId Unique Id of the new template.
   * @param template New template (See ITemplateRegistry for more details)
   * @dev (See TemplateRegistry for more details)
   */
  function addTemplate(
    bytes32 templateCategory,
    bytes32 templateId,
    Template calldata template
  ) external {
    templateRegistry.addTemplate(templateCategory, templateId, template);
  }

  /**
   * @notice Toggles the endorsement of a template. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param templateCategory TemplateCategory of the template to endorse.
   * @param templateId TemplateId of the template to endorse.
   * @dev (See TemplateRegistry for more details)
   */
  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external onlyOwner {
    templateRegistry.toggleTemplateEndorsement(templateCategory, templateId);
  }

  /*//////////////////////////////////////////////////////////////
                          DEPLOY LOGIC
    //////////////////////////////////////////////////////////////*/

  error NotEndorsed(bytes32 templateId);

  /**
   * @notice Clones an implementation and initializes the clone. Caller must be owner.  (`VaultController` via `AdminProxy`)
   * @param templateCategory Category of the template to use.
   * @param templateId Unique Id of the template to use.
   * @param data The data to pass to the clone's initializer.
   * @dev Uses a template from `TemplateRegistry`. The template must be endorsed.
   * @dev Deploys and initializes a clone using `CloneFactory`.
   * @dev Registers the clone in `CloneRegistry`.
   */
  function deploy(
    bytes32 templateCategory,
    bytes32 templateId,
    bytes calldata data
  ) external onlyOwner returns (address clone) {
    Template memory template = templateRegistry.getTemplate(templateCategory, templateId);

    if (!template.endorsed) revert NotEndorsed(templateId);

    clone = cloneFactory.deploy(template, data);

    cloneRegistry.addClone(templateCategory, templateId, clone);
  }

  /*//////////////////////////////////////////////////////////////
                          OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Nominates a new owner for dependency contracts. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param _owner The new `DeploymentController` implementation
   */
  function nominateNewDependencyOwner(address _owner) external onlyOwner {
    IOwned(address(cloneFactory)).nominateNewOwner(_owner);
    IOwned(address(cloneRegistry)).nominateNewOwner(_owner);
    IOwned(address(templateRegistry)).nominateNewOwner(_owner);
  }

  /**
   * @notice Accept ownership of dependency contracts.
   * @dev Must be called after construction.
   */
  function acceptDependencyOwnership() external {
    IOwned(address(cloneFactory)).acceptOwnership();
    IOwned(address(cloneRegistry)).acceptOwnership();
    IOwned(address(templateRegistry)).acceptOwnership();
  }
}