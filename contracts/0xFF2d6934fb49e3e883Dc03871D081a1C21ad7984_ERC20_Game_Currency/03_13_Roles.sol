// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity ^0.8.16;

contract Roles {
  bytes32 internal constant MINTER_ROLE = keccak256("METAFAB_MINTER_ROLE");
  bytes32 internal constant OWNER_ROLE = keccak256("METAFAB_OWNER_ROLE");
}