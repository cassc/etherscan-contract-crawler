// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

interface IMiniMeToken {
  // Events
  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
  event Transfer(address indexed _from, address indexed _to, uint256 _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

  // ERC20 Methods
  function transfer(address _to, uint256 _amount) external returns (bool success);

  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);

  function approve(address _spender, uint256 _amount) external returns (bool success);

  function allowance(address _owner, address _spender) external returns (uint256 remaining);

  function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool success);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function totalSupply() external view returns (uint);

  // Query balance and totalSupply in History
  function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint);

  function totalSupplyAt(uint _blockNumber) external view returns (uint);

  // Generate and destroy tokens
  function generateTokens(address _owner, uint _amount) external returns (bool);

  function destroyTokens(address _owner, uint _amount) external returns (bool);

  // Enable tokens transfers
  function enableTransfers(bool _transfersEnabled) external;

  // Safety Methods
  function claimTokens(address _token) external;
}