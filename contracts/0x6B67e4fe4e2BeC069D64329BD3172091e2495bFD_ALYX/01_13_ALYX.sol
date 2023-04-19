// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title ALYX
 * @notice The main token of the protocol
 * @author AlloyX
 */
contract ALYX is ERC20Upgradeable, AdminUpgradeable {
  /**
   * @notice Initialize the contract
   */
  function initialize() external initializer {
    __AdminUpgradeable_init(msg.sender);
    __ERC20_init("Alyx", "ALYX");
  }

  /**
   * @notice Mint the token
   * @param _account the account to mint to
   * @param _amount the amount to mint
   */
  function mint(address _account, uint256 _amount) external onlyAdmin returns (bool) {
    _mint(_account, _amount);
    return true;
  }

  /**
   * @notice Burn the token
   * @param _account the account to mint to
   * @param _amount the amount to mint
   */
  function burn(address _account, uint256 _amount) external onlyAdmin returns (bool) {
    _burn(_account, _amount);
    return true;
  }
}