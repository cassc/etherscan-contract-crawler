// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

// Contract cannot verify ECDSA signature
error InvalidSignature();

// Message signer address cannot be used to send transaction
error RecoveredMsgSender();

// Signed message hash does not match hash created in smart contract
error InvalidMessageHash();

// Message signed by non whitelisted address
error SignerNotWhitelisted();

// Method is trying to transfer 0 tokens
error TokenZeroValue();

// Lower payment limit not reached
error PaymentTooLow();

// Upper payment limit reached
error PaymentTooHigh();

// Contract tokens limit would be exceeded if assigned to user
error NoAvailableTokens();

// Method is not available in current sale stage
error InvalidSaleStatus();

// User has 0 locked tokens
error ZeroLockedValue();

// User has 0 tokens to unlock with current unlocked percent
error NothingTooClaim();

// User needs to claim all tokens before calling this
error LockedTokensNotWithdrawn();

// User has never bought any tokens
error NoBalanceExists();

// User has no bonus to withdraw
error NoBonusApplied();

// User already claimed bonus
error BonusAlreadyClaimed();