// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title Mintable + Burnable
 * @author AlloyX
 */
interface IMintBurnableERC20 is IERC20Upgradeable {
  function mint(address _account, uint256 _amount) external returns (bool);

  function burn(address _account, uint256 _amount) external returns (bool);
}