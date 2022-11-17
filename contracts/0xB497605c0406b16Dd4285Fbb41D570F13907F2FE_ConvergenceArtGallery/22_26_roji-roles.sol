// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/*
   Roji roles start at the low end. We reserve the first 100 for our own use.
 */

uint256 constant ROJI_ROLE_MINTER = 1 << 0;
uint256 constant ROJI_ROLE_WITHDRAWER = 1 << 1;
uint256 constant ROJI_ROLE_REDEMPTION = 1 << 2;
uint256 constant ROJI_ROLE_BURNER = 1 << 3;

uint256 constant ROJI_ROLE_ADMIN_OPERATIONS = 1 << 4;
uint256 constant ROJI_ROLE_ADMIN_MINTER = 1 << 5;
uint256 constant ROJI_ROLE_ADMIN_ROYALTIES = 1 << 6;
uint256 constant ROJI_ROLE_ADMIN_SETUP = 1 << 7;
uint256 constant ROJI_ROLE_ADMIN_METADATA = 1 << 8;