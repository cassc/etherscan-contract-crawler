// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './HegicPool/IHegicPoolMetadata.sol';
import './IGovernable.sol';

interface IZHegic is IERC20, IGovernable {
  function pool() external returns (IHegicPoolMetadata);
  
  function setPool(address _newPool) external;
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}