// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITradeTrustSBT.sol";
import "./ITradeTrustTokenRestorable.sol";
import "./ITradeTrustTokenBurnable.sol";
import "./ITradeTrustTokenMintable.sol";

interface ITradeTrustToken is
  ITradeTrustTokenMintable,
  ITradeTrustTokenBurnable,
  ITradeTrustTokenRestorable,
  ITradeTrustSBT
{}