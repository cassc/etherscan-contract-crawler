// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Clones } from "openzeppelin-contracts/proxy/Clones.sol";
import { Owned } from "../utils/Owned.sol";
import { Template } from "../interfaces/vault/ITemplateRegistry.sol";

/**
 * @title   CloneFactory
 * @author  RedVeil
 * @notice  Creates clones from a template and initializes it.
 *
 * Clones get created via the `DeploymentController`.
 */
contract CloneFactory is Owned {
  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  /// @param _owner `AdminProxy`
  constructor(address _owner) Owned(_owner) {}

  /*//////////////////////////////////////////////////////////////
                          DEPLOY LOGIC
    //////////////////////////////////////////////////////////////*/

  event Deployment(address indexed clone);

  error DeploymentInitFailed();
  error NotEndorsed(bytes32 templateKey);

  /**
   * @notice Clones an implementation and initializes the clone. Caller must be owner. (`DeploymentController`)
   * @param template The template to use for the deployment. (See TemplateRegistry for more details)
   * @param data The data to pass to the clone's initializer.
   */
  function deploy(Template calldata template, bytes calldata data) external onlyOwner returns (address clone) {
    clone = Clones.clone(template.implementation);

    bool success = true;
    if (template.requiresInitData) (success, ) = clone.call(data);

    if (!success) revert DeploymentInitFailed();

    emit Deployment(clone);
  }
}