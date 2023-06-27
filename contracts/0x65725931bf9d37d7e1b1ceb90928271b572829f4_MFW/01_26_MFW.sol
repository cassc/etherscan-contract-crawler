// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@                               @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@      @@@@@@@     @@@@@@@      @@@@@@
// @@@@@@      @@@@@@@     @@@@@@@      @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@                               @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@                               @@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

/// @title MFW wearables contract
contract MFW is ERC1155Creator {
    constructor() ERC1155Creator() {}

    function name() external pure returns (string memory _name) {
        return "MetaFactory Wearables";
    }

    function symbol() external pure returns (string memory _symbol) {
        return "MFW";
    }
}