// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PPAgentV2Flags {
  // Keeper pass this flags withing execute() transaction
  uint256 internal constant FLAG_ACCEPT_MAX_BASE_FEE_LIMIT = 0x01;
  uint256 internal constant FLAG_ACCRUE_REWARD = 0x02;

  // Job owner uses CFG_* flags to configure a job options
  uint256 internal constant CFG_ACTIVE = 0x01;
  uint256 internal constant CFG_USE_JOB_OWNER_CREDITS = 0x02;
  uint256 internal constant CFG_ASSERT_RESOLVER_SELECTOR = 0x04;
  uint256 internal constant CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT = 0x08;

  uint256 internal constant BM_CLEAR_CONFIG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00;
  uint256 internal constant BM_CLEAR_CREDITS = 0xffffffffffffffffffffffffffffffff0000000000000000000000ffffffffff;
  uint256 internal constant BM_CLEAR_LAST_UPDATE_AT = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
}