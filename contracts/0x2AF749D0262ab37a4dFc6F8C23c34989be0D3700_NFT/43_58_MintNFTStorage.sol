// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract MintNFTStorage {
    CountersUpgradeable.Counter internal _tokenIdCounter;
}