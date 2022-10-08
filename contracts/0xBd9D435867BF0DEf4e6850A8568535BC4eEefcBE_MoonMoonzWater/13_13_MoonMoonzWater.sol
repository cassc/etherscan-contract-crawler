// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MoonMoonzWater is Ownable, Pausable, ERC20("Moon Moonz Water", "WATER"), ERC20Permit("Moon Moonz Water") {
  /* -------------------------------------------------------------------------- */
  /*                                  Variables                                 */
  /* -------------------------------------------------------------------------- */

  mapping(address => bool) public controllers;

  /* -------------------------------------------------------------------------- */
  /*                                  Modifiers                                 */
  /* -------------------------------------------------------------------------- */

  modifier onlyController() {
    require(controllers[msg.sender], "Caller is not a controller");
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Constructor                                */
  /* -------------------------------------------------------------------------- */

  constructor() {
    super._mint(msg.sender, 50 ether);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Tokens                                   */
  /* -------------------------------------------------------------------------- */

  function mint(address to, uint256 value) external onlyController {
    // require(totalSupply() + value <= MAX_SUPPLY, "Max supply exceeded");
    super._mint(to, value);
  }

  function burn(address from, uint256 value) external onlyController {
    super._burn(from, value);
  }

  function rate() external view returns (uint256) {
    if (super.totalSupply() < 5_000_000 ether) return 10 ether;
    else return 3 ether;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Maintenance                                */
  /* -------------------------------------------------------------------------- */

  function setPaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i; i < addrs.length; i++) controllers[addrs[i]] = state;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Overrides                                 */
  /* -------------------------------------------------------------------------- */

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}