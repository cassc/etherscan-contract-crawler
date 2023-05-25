// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "tornado-governance/contracts/v2-vault-and-gas/interfaces/ITornadoVault.sol";

interface ITornadoGovernance {
  function lockedBalance(address account) external view returns (uint256);

  function userVault() external view returns (ITornadoVault);
}