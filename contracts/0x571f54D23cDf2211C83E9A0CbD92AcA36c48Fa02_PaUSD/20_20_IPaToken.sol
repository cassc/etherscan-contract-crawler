// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IAccessControl } from "@openzeppelin4.8.2/contracts/access/IAccessControl.sol";
import { IERC2612 } from "@openzeppelin4.8.2/contracts/interfaces/draft-IERC2612.sol";

interface IPaToken is IERC2612 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function accessController() external view returns (IAccessControl);
}