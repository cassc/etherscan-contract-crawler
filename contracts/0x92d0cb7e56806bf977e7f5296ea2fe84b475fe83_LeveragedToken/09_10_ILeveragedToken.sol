// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ILeveragedToken {
  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the net asset value for the token.
  function nav() external view returns (uint256);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint some token to someone.
  /// @param to The address of recipient.
  /// @param amount The amount of token to mint.
  function mint(address to, uint256 amount) external;

  /// @notice Burn some token from someone.
  /// @param from The address of owner to burn.
  /// @param amount The amount of token to burn.
  function burn(address from, uint256 amount) external;
}