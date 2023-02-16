// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";

contract KrystalCharacterStorage is ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuard {
    // string public override name;
    // string public override symbol;
    string public tokenUriPrefix;
    address public characterContract;

    // Backend signer for verifying the claim
    address public verifier;

    mapping(uint256 => bool) public minted;
}