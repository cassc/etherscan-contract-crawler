// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "IERC20Metadata.sol";

interface IXfaiPool is IERC20Metadata {
  function getXfaiCore() external view returns (address);

  function poolToken() external view returns (address);

  function initialize(address _token, address _xfaiFactory) external;

  function getStates() external view returns (uint, uint);

  function update(uint _reserveBalance, uint _weightBalance) external;

  function mint(address _to, uint _amount) external;

  function burn(address _to, uint _amount) external;

  function linkedTransfer(address _token, address _to, uint256 _value) external;

  event Sync(uint _reserve, uint _weight);
  event Write(uint _reserve, uint _weight, uint _blockTimestamp);
}