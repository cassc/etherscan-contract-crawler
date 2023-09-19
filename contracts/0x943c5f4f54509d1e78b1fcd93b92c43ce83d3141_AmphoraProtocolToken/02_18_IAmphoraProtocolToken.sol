// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

/// @title interface to interact with TokenDelgate
interface IAmphoraProtocolToken {
  /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when invalid address
  error AmphoraProtocolToken_InvalidAddress();

  /// @notice Thrown when invalid supply
  error AmphoraProtocolToken_InvalidSupply();

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  function mint(address _dst, uint256 _rawAmount) external;
}