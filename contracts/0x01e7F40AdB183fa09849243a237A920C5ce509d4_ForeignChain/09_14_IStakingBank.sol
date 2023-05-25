// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingBank is IERC20 {
  function receiveApproval(address _from) external returns (bool success);

  function withdraw(uint256 _value) external returns (bool success);

  function create(address _id, string calldata _location) external;

  function update(address _id, string calldata _location) external;

  function addresses(uint256 _ix) external view returns (address);

  function validators(address _id) external view returns (address id, string memory location);

  function getNumberOfValidators() external view returns (uint256);
}