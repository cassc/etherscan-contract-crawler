// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IAlloyxVaultToken
 * @author AlloyX
 */
interface IAlloyxVaultToken {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function mint(uint256 _tokenToMint, address _address) external;

  function burn(uint256 _tokenBurn, address _address) external;

  function snapshot() external returns (uint256);

  function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

  function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
}