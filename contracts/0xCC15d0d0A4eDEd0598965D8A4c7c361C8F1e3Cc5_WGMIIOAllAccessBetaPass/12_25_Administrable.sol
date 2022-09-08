// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ContractsCannotMint();
error NotAuthorized();

abstract contract Administrable is AccessControlEnumerable, Ownable{

  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  constructor(){
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyOperator {
    if(!hasRole(OPERATOR_ROLE, msg.sender)) revert NotAuthorized();
    _;
  }

  modifier onlyOperatorsAndOwner {
    if(owner() != msg.sender  && !hasRole(OPERATOR_ROLE, msg.sender)) revert NotAuthorized();
    _;
  }

  modifier noContracts {
    if(msg.sender != tx.origin) revert ContractsCannotMint();
    _;
  }
}