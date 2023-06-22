// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Saffron Fixed Income Vault Bearer Token
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Vaults create these tokens to give vault participants fungible ownership of their positions
contract VaultBearerToken is ERC20 {
  /// @notice The address of the vault that owns this token
  address public vault;

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    vault = msg.sender;
  }

  /// @notice Mints tokens
  /// @param _to The address to mint to
  /// @param _amount The amount to mint
  /// @dev Only the owning vault can do this
  function mint(address _to, uint256 _amount) external {
    require(msg.sender == vault, "MBV");
    require(_amount > 0, "NEI");
    _mint(_to, _amount);
  }

  /// @notice Burns tokens
  /// @param _account The address to burn from
  /// @param _amount The amount to burn
  /// @dev Only the owning vault can do this
  function burn(address _account, uint256 _amount) public {
    require(msg.sender == vault, "MBV");
    require(_amount > 0, "NEI");
    _burn(_account, _amount);
  }
}