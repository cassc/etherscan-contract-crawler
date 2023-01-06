// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface SignatureAccessControllerInterface {
  function isSignerValid(address walletAddress) external view returns (bool);
}