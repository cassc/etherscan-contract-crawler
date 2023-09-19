// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./ICoverERC20.sol";

/**
 * @title Cover contract interface. See {Cover}.
 * @author crypto-pumpkin@github
 */
interface ICover {
  event NewCoverERC20(address);

  function getCoverDetails()
    external view returns (string memory _name, uint48 _expirationTimestamp, address _collateral, uint256 _claimNonce, ICoverERC20 _claimCovToken, ICoverERC20 _noclaimCovToken);
  function expirationTimestamp() external view returns (uint48);
  function collateral() external view returns (address);
  function claimCovToken() external view returns (ICoverERC20);
  function noclaimCovToken() external view returns (ICoverERC20);
  function name() external view returns (string memory);
  function claimNonce() external view returns (uint256);

  function redeemClaim() external;
  function redeemNoclaim() external;
  function redeemCollateral(uint256 _amount) external;

  /// @notice access restriction - owner (Protocol)
  function mint(uint256 _amount, address _receiver) external;

  /// @notice access restriction - dev
  function setCovTokenSymbol(string calldata _name) external;
}