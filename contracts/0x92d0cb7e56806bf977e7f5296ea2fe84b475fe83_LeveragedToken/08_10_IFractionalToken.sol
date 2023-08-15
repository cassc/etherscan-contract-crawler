// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IFractionalToken {
  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the net asset value for the token.
  function nav() external view returns (uint256);

  /// @notice Compute the new nav with multiple.
  /// @param multiple The multiplier used to update the nav, multiplied by 1e18.
  /// @return newNav The new net asset value of the token.
  function getNav(int256 multiple) external view returns (uint256 newNav);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Update the net asset value by times `(1 + multiple / 1e18)`.
  /// @param multiple The multiplier used to update the nav, multiplied by 1e18.
  /// @return newNav The new net asset value of the token.
  function updateNav(int256 multiple) external returns (uint256 newNav);

  /// @notice Update the net asset value by direct setting.
  /// @param newNav The new net asset value, multiplied by 1e18.
  function setNav(uint256 newNav) external;

  /// @notice Mint some token to someone.
  /// @param to The address of recipient.
  /// @param amount The amount of token to mint.
  function mint(address to, uint256 amount) external;

  /// @notice Burn some token from someone.
  /// @param from The address of owner to burn.
  /// @param amount The amount of token to burn.
  function burn(address from, uint256 amount) external;
}