// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * Since structs are packed in storage but we don't fill the next slot anyway,
 * we use bigger numbers than we need in case we need to adapt the card usage
 * with different interfaces or collections.
 */
struct Card {
  uint256 id;
  uint8 rarity; // 0-5
  uint8 personality; // Typing for battle effectiveness, 11 types so 0-10.
  uint16 hp;
  uint16 attack;
  uint16 attackModifier;
  uint16 defence;
  uint16 defenceModifier;
  uint16 speed;
}