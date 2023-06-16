// SPDX-License-Identifier: GPL-3.0

import { Fact, FactSignature } from "relic-sdk/packages/contracts/lib/Facts.sol";
import { FactSigs } from "relic-sdk/packages/contracts/lib/FactSigs.sol";

pragma solidity ^0.8.19;

interface Validator {
  function validate(Fact memory fact, bytes32 expectedSlot, uint256 expectedBlock, address account)
    external
    pure
    returns (bool);
}

/// FactValidator abstracts proof validation functionality
contract FactValidator is Validator {
  function validate(Fact memory fact, bytes32 expectedSlot, uint256 expectedBlock, address account)
    external
    pure
    returns (bool)
  {
    FactSignature expectedSig = FactSigs.storageSlotFactSig(expectedSlot, expectedBlock);
    if (keccak256(abi.encodePacked(fact.sig)) != keccak256(abi.encodePacked(expectedSig))) {
      return false;
    }

    if (fact.account != account) {
      return false;
    }

    return true;
  }
}