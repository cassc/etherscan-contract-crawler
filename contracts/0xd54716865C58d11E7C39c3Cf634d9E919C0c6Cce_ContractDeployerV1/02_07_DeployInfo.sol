// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct DeployInfo {
  mapping(uint => address) addressByVersion;
  mapping(uint => address) deployerByVersion;
  address[] addresses;
  address[] deployers;
  uint[] versions;
}