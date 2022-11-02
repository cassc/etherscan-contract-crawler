// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface SignatureAccessControllerInterface {
  function isSignatureValid(address walletAddress) external view returns (bool);
}