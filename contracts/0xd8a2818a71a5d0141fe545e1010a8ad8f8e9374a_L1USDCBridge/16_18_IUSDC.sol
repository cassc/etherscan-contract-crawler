// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUSDC is IERC20 {
  function isMinter(address account) external view returns (bool);

  function burn(uint256 amount) external;

  function mint(address account, uint256 amount) external;

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function updateBlacklister(address _newBlacklister) external;

  function updatePauser(address _newPauser) external;

  function updateMasterMinter(address _newMasterMinter) external;

  function transferOwnership(address newOwner) external;

  function removeMinter(address minter) external returns (bool);
}