// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase, var-name-mixedcase

interface IStakeDAOBoostDelegation {
  function boost(
    address _to,
    uint256 _amount,
    uint256 _endtime
  ) external;

  function boost(
    address _to,
    uint256 _amount,
    uint256 _endtime,
    address _from
  ) external;

  function checkpoint_user(address _user) external;

  function approve(address _spender, uint256 _value) external returns (bool);

  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (bool);

  function increaseAllowance(address _spender, uint256 _added_value) external returns (bool);

  function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool);

  function balanceOf(address _user) external view returns (uint256);

  function adjusted_balance_of(address _user) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function delegated_balance(address _user) external view returns (uint256);

  function received_balance(address _user) external view returns (uint256);

  function delegable_balance(address _user) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function nonces(address _user) external view returns (uint256);
}