// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Roles} from "../libraries/Roles.sol";
import {ITargetInit} from "./interfaces/ITarget.sol";
import {CloneFactory} from "./CloneFactory.sol";
import {DeployerStorage} from "./DeployerStorage.sol";

contract Deployer is
  OwnableUpgradeable,
  AccessControlEnumerableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable,
  CloneFactory
{
  using Clones for address;
  using DeployerStorage for DeployerStorage.Layout;

  event ContractDeployed(address newContract);

  function initialize(address admin) public initializer {
    __Deployer_init(admin);
  }

  function __Deployer_init(address admin) internal onlyInitializing {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __Deployer_init_unchained(admin);
  }

  function __Deployer_init_unchained(address admin) internal onlyInitializing {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(Roles.MANAGER_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(Roles.MANAGER_ROLE, admin);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // TODO: only support given target addresses?
  // TODO: voucher to deploy contract?
  function deployContract(
    address target,
    string calldata _name,
    string calldata _symbol
  ) public returns (address) {
    address clone = createClone(target);

    ITargetInit(clone).initialize(_name, _symbol);
    ITargetInit(clone).transferOwnership(msg.sender);

    emit ContractDeployed(clone);
    return clone;
  }
}