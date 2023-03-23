// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IReferral {
  struct Referral {
    uint64 rebatePct; // % of fee
    uint64 referralRebatePct; // % of fee
    address referrer;
    bytes32 referralCode;
  }

  function getReferral(address _user) external view returns (Referral memory);

  function getReferralByCode(
    bytes32 code
  ) external view returns (Referral memory);
}