// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Errors} from '../libraries/Errors.sol';
import {Ownable2Step} from '../dependencies/openzeppelin/Ownable2Step.sol';
import {AccessControl} from '../dependencies/openzeppelin/AccessControl.sol';

abstract contract HopeOneRole is Ownable2Step, AccessControl {
  bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

  function isOperator(address _operator) external view returns (bool) {
    return hasRole(OPERATOR_ROLE, _operator);
  }

  function addOperator(address _operator) external onlyOwner {
    require(_operator != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    _grantRole(OPERATOR_ROLE, _operator);
  }

  function removeOperator(address _operator) external onlyOwner {
    require(_operator != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    _revokeRole(OPERATOR_ROLE, _operator);
  }
}