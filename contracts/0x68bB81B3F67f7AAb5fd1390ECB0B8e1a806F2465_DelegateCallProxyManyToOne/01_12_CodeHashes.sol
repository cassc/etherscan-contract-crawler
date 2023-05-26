// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/**
 * @dev Because we use the code hashes of the proxy contracts for proxy address
 * derivation, it is important that other packages have access to the correct
 * values when they import the salt library.
 */
library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = 0x63d9f7b5931b69188c8f6b806606f25892f1bb17b7f7e966fe3a32c04493aee4;
  bytes32 internal constant MANY_TO_ONE_CODEHASH = 0xa035ad05a1663db5bfd455b99cd7c6ac6bd49269738458eda140e0b78ed53f79;
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = 0x11c370493a726a0ffa93d42b399ad046f1b5a543b6e72f1a64f1488dc1c58f2c;
}