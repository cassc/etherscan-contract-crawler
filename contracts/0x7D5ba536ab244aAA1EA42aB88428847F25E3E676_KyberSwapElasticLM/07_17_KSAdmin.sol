// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract KSAdmin {
  address public admin;
  mapping(address => bool) public operators; // address => bool

  event TransferAdmin(address indexed admin);
  event UpdateOperator(address indexed user, bool grantOrRevoke);

  modifier isAdmin() {
    require(msg.sender == admin, 'forbidden');
    _;
  }

  modifier isOperator() {
    require(operators[msg.sender], 'forbidden');
    _;
  }

  constructor() {
    admin = msg.sender;
    operators[msg.sender] = true;
  }

  function transferAdmin(address _admin) external virtual isAdmin {
    require(_admin != address(0), 'forbidden');

    admin = _admin;

    emit TransferAdmin(_admin);
  }

  function updateOperator(address user, bool grantOrRevoke) external isAdmin {
    operators[user] = grantOrRevoke;

    emit UpdateOperator(user, grantOrRevoke);
  }
}