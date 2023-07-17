/// SPDX-License-Identifier CC0-1.0
pragma solidity 0.8.17;

/// @title IWrappedReaperRenderer.sol
/// @author unknown
/// @notice Defines the high-level interface to the decoupled on-chain renderer.
interface IWrappedReaperRenderer {

  /// @notice Computes a raw WrappedReaper Bar token SVG for the provided parameters.
  /// @param tokenId Identifier of the token.
  /// @param stake The amount of $RG staked inside the token.
  /// @param mintBlock The block depth when the token was minted.
  /// @param minter The address responsible for minting the token.
  /// @param saturation_ Color vividness (0 -> 3).
  /// @param phase_ Shadow positioning (0 -> 3).
  /// @return SVG XML string.
  function barTokenURIDataImage(uint256 tokenId, uint256 stake, uint256 mintBlock, address minter, uint256 saturation_, uint256 phase_) external pure returns (bytes memory);

  /// @notice Computes a raw WrappedReaper Burn token SVG for the provided parameters.
  /// @param saturation_ Color vividness (0 -> 3).
  /// @return SVG XML string.
  function burnTokenURIDataImage(uint256 saturation_) external pure returns (bytes memory);

}