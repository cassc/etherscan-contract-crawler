// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import {CREATE3} from '@rari-capital/solmate/src/utils/CREATE3.sol';
import {IDeterministicFactory} from '../interfaces/IDeterministicFactory.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

contract DeterministicFactory is AccessControl, IDeterministicFactory {
  /// @inheritdoc IDeterministicFactory
  bytes32 public constant override ADMIN_ROLE = keccak256('ADMIN_ROLE');
  /// @inheritdoc IDeterministicFactory
  bytes32 public constant override DEPLOYER_ROLE = keccak256('DEPLOYER_ROLE');

  constructor(address _admin, address _deployer) {
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(DEPLOYER_ROLE, ADMIN_ROLE);
    _setupRole(ADMIN_ROLE, _admin);
    _setupRole(DEPLOYER_ROLE, _deployer);
  }

  /// @inheritdoc IDeterministicFactory
  function deploy(
    bytes32 _salt,
    bytes memory _creationCode,
    uint256 _value
  ) external payable override onlyRole(DEPLOYER_ROLE) returns (address _deployed) {
    _deployed = CREATE3.deploy(_salt, _creationCode, _value);
  }

  /// @inheritdoc IDeterministicFactory
  function getDeployed(bytes32 _salt) external view override returns (address) {
    return CREATE3.getDeployed(_salt);
  }
}