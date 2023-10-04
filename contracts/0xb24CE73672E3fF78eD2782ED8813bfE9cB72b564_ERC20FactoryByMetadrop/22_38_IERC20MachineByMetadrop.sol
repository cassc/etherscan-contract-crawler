// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IConfigStructures} from "../../Global/IConfigStructures.sol";
import {IERC20ConfigByMetadrop} from "../ERC20/IERC20ConfigByMetadrop.sol";
import {IERC20ByMetadrop, ERC20ByMetadrop} from "../ERC20/ERC20ByMetadrop.sol";
import {IErrors} from "../../Global/IErrors.sol";

/**
 * @dev Metadrop ERC-20 contract deployer
 *
 * @dev Implementation of the {IERC20DeployerByMetasdrop} interface.
 *
 * Lightweight deployment module for use with template contracts
 */
interface IERC20MachineByMetadrop is IERC20ConfigByMetadrop, IErrors {
  /**
   * @dev function {deploy}
   *
   * Deploy a fresh instance
   */
  function deploy(
    bytes32 salt_,
    bytes memory args_
  ) external payable returns (address erc20ContractAddress_);
}