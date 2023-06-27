// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IAccessControl } from "@openzeppelin4.8.2/contracts/access/AccessControl.sol";
import { IPaToken } from "./interfaces/IPaToken.sol";
import { ERC20 } from "@openzeppelin4.8.2/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin4.8.2/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { Errors } from "../libraries/Errors.sol";
import { Roles } from "../libraries/Roles.sol";

contract PaUSD is ERC20, ERC20Permit, IPaToken {
  IAccessControl public immutable override accessController;

  modifier onlyMinter() {
    if (!accessController.hasRole(Roles.MINTER_ROLE, msg.sender)) {
      revert Errors.CALLER_IS_NOT_A_MINTER();
    }
    _;
  }

  constructor(IAccessControl _accessController) ERC20("paUSD Stablecoin", "paUSD") ERC20Permit("paUSD") {
    if (address(_accessController) == address(0)) {
      revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
    }

    accessController = _accessController;
  }

  function mint(address to, uint256 amount) external override onlyMinter {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyMinter {
    _burn(from, amount);
  }
}