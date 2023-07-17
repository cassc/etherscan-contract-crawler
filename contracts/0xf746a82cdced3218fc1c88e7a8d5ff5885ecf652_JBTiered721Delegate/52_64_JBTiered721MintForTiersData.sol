// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member tierIds The IDs of the tier to mint within.
/// @custom:member beneficiary The beneficiary to mint for.
struct JBTiered721MintForTiersData {
    uint16[] tierIds;
    address beneficiary;
}