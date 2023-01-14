// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

library StadiumUtils {
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    uint8 public constant O_PLAYER = 0x1;
    uint8 public constant O_TEAM = 0x2;
    uint8 public constant O_LEAGUES = 0x3;
    uint8 public constant O_PROPERTIES = 0x4;
    uint8 public constant O_CHANNELS = 0x5;
    uint8 public constant O_PASSES = 0x6;

    function recoverAddress(bytes32 data, bytes memory signature) pure internal returns (address) {
        return data.toEthSignedMessageHash().recover(signature);
    }
}