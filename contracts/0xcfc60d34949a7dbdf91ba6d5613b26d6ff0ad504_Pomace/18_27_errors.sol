// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *      Shared Errors       *
 * -----------------------  */

error NoAccess();

/* ------------------------ *
 *      Pomace Errors       *
 * -----------------------  */

/// @dev asset already registered
error PM_AssetAlreadyRegistered();

/// @dev margin engine already registered
error PM_EngineAlreadyRegistered();

/// @dev amounts length specified to batch settle doesn't match with tokenIds
error PM_WrongArgumentLength();

/// @dev cannot settle an unexpired option
error PM_NotExpired();

/// @dev settlement price is not finalized yet
error PM_PriceNotFinalized();

/// @dev cannot mint token after expiry
error PM_InvalidExpiry();

/// @dev cannot mint token with zero settlement window
error PM_InvalidExerciseWindow();

/// @dev cannot mint token with zero settlement window
error PM_InvalidCollateral();

/// @dev burn or mint can only be called by corresponding engine.
error PM_Not_Authorized_Engine();

/* ---------------------------- *
 *   Common BaseEngine Errors   *
 * ---------------------------  */

/// @dev account is not healthy / account is underwater
error BM_AccountUnderwater();

/// @dev msg.sender is not authorized to ask margin account to pull token from {from} address
error BM_InvalidFromAddress();