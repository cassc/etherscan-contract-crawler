// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC20ByMetadrop} from "../ERC20/ERC20ByMetadrop.sol";
import {IERC20MachineByMetadrop} from "./IERC20MachineByMetadrop.sol";
import {Revert} from "../../Global/Revert.sol";

/**
 * @dev Metadrop ERC-20 contract deployer
 *
 * @dev Implementation of the {IERC20MachineByMetasdrop} interface.
 *
 * Lightweight deployment module for use with template contracts
 */
contract ERC20MachineByMetadrop is Context, IERC20MachineByMetadrop, Revert {
  address immutable factory;

  /**
   * @dev {constructor}
   *
   * @param factory_ Address of the factory
   */
  constructor(address factory_) {
    factory = factory_;
  }

  /**
   * @dev {onlyFactory}
   *
   * Throws if called by any account other than the factory.
   */
  modifier onlyFactory() {
    if (factory != _msgSender()) {
      _revert(CallerIsNotFactory.selector);
    }
    _;
  }

  /**
   * @dev function {deploy}
   *
   * Deploy a fresh instance
   */
  function deploy(
    bytes32 salt_,
    bytes memory args_
  ) external payable onlyFactory returns (address erc20ContractAddress_) {
    bytes memory deploymentData = abi.encodePacked(
      type(ERC20ByMetadrop).creationCode,
      args_
    );

    assembly {
      erc20ContractAddress_ := create2(
        0,
        add(deploymentData, 0x20),
        mload(deploymentData),
        salt_
      )
      if iszero(extcodesize(erc20ContractAddress_)) {
        revert(0, 0)
      }
    }
  }
}