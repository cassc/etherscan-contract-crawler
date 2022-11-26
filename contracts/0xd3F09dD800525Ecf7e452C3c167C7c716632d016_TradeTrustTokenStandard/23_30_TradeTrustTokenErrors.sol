// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface TradeTrustTokenErrors {
  error TokenNotSurrendered();

  error InvalidTokenId();

  error TokenExists();

  error TransferFailure();
}