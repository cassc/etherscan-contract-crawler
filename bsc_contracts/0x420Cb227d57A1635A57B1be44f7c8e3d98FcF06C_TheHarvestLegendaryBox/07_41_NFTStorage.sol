// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract NFTStorage {
    string internal _baseTokenURI;
    CountersUpgradeable.Counter internal _tokenIdCounter;
    uint256 internal _maxTokenSupply;
    bool internal _burnEnabled;
}