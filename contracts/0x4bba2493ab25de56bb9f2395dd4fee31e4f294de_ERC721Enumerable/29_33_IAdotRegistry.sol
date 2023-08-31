// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// ADOT + VUCA + LightLink + Pellar 2023

interface IAdotRegistry {
  function getPlatformFeeReceiver() external view returns (address);

  function getVerifier() external view returns (address);

  function getMultisig() external view returns (address);

  function getPlatformFee() external view returns (uint96);

  function feeDenominator() external view returns (uint96);

  function getFeeAmount(uint256 amount) external view returns (uint256 fee, uint256 received);

  function getRootURI() external view returns (string memory);
}