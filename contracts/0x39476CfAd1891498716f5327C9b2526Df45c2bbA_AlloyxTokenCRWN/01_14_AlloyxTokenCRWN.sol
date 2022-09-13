// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/IMintBurnableERC20.sol";
import "./AdminUpgradeable.sol";

contract AlloyxTokenCRWN is ERC20Upgradeable, AdminUpgradeable {
  function initialize() external initializer {
    __AdminUpgradeable_init(msg.sender);
    __ERC20_init("Crown Gold-Test", "CRWNT");
  }

  function mint(address _account, uint256 _amount) external onlyAdmin returns (bool) {
    _mint(_account, _amount);
    return true;
  }

  function burn(address _account, uint256 _amount) external onlyAdmin returns (bool) {
    _burn(_account, _amount);
    return true;
  }

  function contractName() external pure returns (string memory) {
    return "AlloyxTokenCRWN";
  }
}