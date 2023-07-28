// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* ------------------------ *
 *      Shared Errors       *
 * -----------------------  */

error NoAccess();

/* ------------------------ *
 *      SDYC Errors          *
 * -----------------------  */

error NotPermissioned();
error BadFee();
error BadAddress();
error BadOracleDecimals();
error FeesPending();
error InvalidSignature();

/* ------------------------ *
 *    Aggregators Errors    *
 * -----------------------  */
error RoundDataReported();
error StaleAnswer();
error Overflow();