// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/presets/ERC1155PresetMinterPauserUpgradeable.sol";

contract KrystalCollectiblesStorage is ERC1155PresetMinterPauserUpgradeable, ReentrancyGuard {
    string public name;
    string public symbol;
    string public tokenUriPrefix;
}