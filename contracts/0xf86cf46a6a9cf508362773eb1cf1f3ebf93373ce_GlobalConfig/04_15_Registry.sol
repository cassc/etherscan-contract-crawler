// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Registry {

  /***************************** ROLE NAME CONSTANT VARIABLES  ***********************************/

  // SUPER_ADMIN_ROLE
  bytes32 internal constant SUPER_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;

  // keccak256("ADMIN_ROLE");
  bytes32 internal constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;

  // keccak256("only.on.chain");
  bytes32 internal constant ONLY_ON_CHAIN = 0x0b7322ebc56f27a124c063802688bbc3635a2ce3f24abda3e4adaec5fce31196;
}