// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface ICollabUpgradable {
  event EvStampUpdate(address user, string id, string content);
  event EvProtectedActivitySet(string id, bool protected);
  event EvSignerSet(address signer, bool valid);

  error InvalidSigner();
  error ProtectedActivity();
  error NotProtectedActivity();
  error SignatureExpired();

  function saveStamp(
    string calldata id,
    string calldata content,
    uint256 deadline,
    bytes calldata signature
  ) external;

  function saveStamp(string calldata id, string calldata content) external;

  function isProtected(string calldata id) external view returns (bool);
}