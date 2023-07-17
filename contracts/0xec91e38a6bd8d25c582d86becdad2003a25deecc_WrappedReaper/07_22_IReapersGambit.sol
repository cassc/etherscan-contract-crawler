/// SPDX-License-Identifier CC0-1.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReapersGambit is IERC20 {
  function CheatDeath(address account) external;
  function AcceptDeath(address account) external;
  function KnowDeath(address account) external view returns (uint256);
}