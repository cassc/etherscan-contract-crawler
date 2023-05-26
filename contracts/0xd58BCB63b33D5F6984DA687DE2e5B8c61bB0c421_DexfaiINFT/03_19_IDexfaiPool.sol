// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

interface IDexfaiPool {
  function getCurrentIndex() external view returns (uint16 index);

  function getNthObservation(
    uint _n
  ) external view returns (uint timestamp, uint rCumulative, uint wCumulative);

  function getCumulativeLast()
    external
    view
    returns (uint timestamp, uint rCumulative, uint wCumulative);

  function ringBufferNonce() external view returns (uint);

  function observations(uint observation) external view returns (uint, uint, uint);

  function getDexfaiCore() external view returns (address);

  function poolToken() external view returns (address);

  function initialize(address _token, address _dexfaiFactory) external;

  function getStates() external view returns (uint, uint, uint);

  function update(uint _balance, uint _r, uint _w) external;

  function mint(address _to, uint _amount) external;

  function burn(address _to, uint _amount) external;

  function safeTransfer(address _token, address _to, uint256 _value) external;

  function totalSupply() external view returns (uint);

  function transfer(address _recipient, uint _amount) external returns (bool);

  function decimals() external view returns (uint8);

  function balanceOf(address) external view returns (uint);

  function transferFrom(address _sender, address _recipient, uint _amount) external returns (bool);

  function approve(address _spender, uint _value) external returns (bool);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function permit(
    address _owner,
    address _spender,
    uint _value,
    uint _deadline,
    uint8 _v,
    bytes32 _re,
    bytes32 _s
  ) external;

  function nonces(address _owner) external view returns (uint);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  event Sync(uint _reserve, uint _w);
  event Transfer(address indexed _from, address indexed _to, uint _amount);
  event Approval(address indexed _owner, address indexed _spender, uint _amount);
  event Write(uint _r, uint _w, uint _blockTimestamp);
}