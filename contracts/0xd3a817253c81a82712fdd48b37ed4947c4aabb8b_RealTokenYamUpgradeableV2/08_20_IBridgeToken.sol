// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgeToken {
  function rules() external view returns (uint256[] memory, uint256[] memory);

  function rule(uint256 ruleId) external view returns (uint256, uint256);

  function owner() external view returns (address);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool);

  function canTransfer(
    address _from,
    address _to,
    uint256 _amount
  )
    external
    view
    returns (
      bool,
      uint256,
      uint256
    );

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}