// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { SafeERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Vault_V2 {
  using SafeERC20 for IERC20;

  uint private operatorsCount;
  mapping (address => bool) private operators;

  // Модификатор доступа оператора
  modifier OnlyOperator() {
    require(operators[msg.sender], 'Permission denied: Operator');
    _;
  }

  constructor() {
    operators[msg.sender] = true;
    operatorsCount += 1;
  }

  receive() external payable {}

  /** Internal: get token allowance */
  function __getAllowance__(IERC20 _token, address _spender) internal view returns (uint256) {
    return _token.allowance(address(this), _spender);
  }

  /** Retrieve token balance */
  function __getTokenBalance(IERC20 _token) view public returns (uint256) {
    return _token.balanceOf(address(this));
  }

  /** Add operator */
  function __addOperator(address _operator) public OnlyOperator {
    operators[_operator] = true;
    operatorsCount += 1;
  }

  /** Remove operator */
  function __removeOperator(address _operator) public OnlyOperator {
    require(operatorsCount > 1, 'There must be at least one operator');

    delete operators[_operator];
    operatorsCount -= 1;
  }

  /** Send Wei to address */
  function __sendWei(address payable _target, uint _amount) public OnlyOperator {
    (bool success, ) = _target.call{ value: _amount }('');
    require(success, 'Failed to send wei');
  }

  /** Transfer token to address */
  function __transferToken(address _target, uint _amount, IERC20 _token) public OnlyOperator {
    _token.safeTransfer(_target, _amount);
  }

  /** Set token allowance */
  function __setTokenAllowance(IERC20 _token, address _spender, uint _amount) public OnlyOperator {
     _token.safeApprove(_spender, 0);
     _token.safeApprove(_spender, _amount);
  }

  /** Make swap */
  function __proxyCall(
    address _proxyAddress,
    bytes calldata _callData,
    uint256 _wei
  ) payable public OnlyOperator {
    (bool success, bytes memory err) = _proxyAddress.call{ value: _wei }(_callData);
    require(success, string(err));
  }
}