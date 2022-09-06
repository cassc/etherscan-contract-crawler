//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/presets/ERC1155PresetMinterPauserUpgradeable.sol";

import "./RaffleV2.sol";

contract RaffleV3 is RaffleV2 {
    ERC1155PresetMinterPauserUpgradeable public key;
    mapping(uint256 => bool) private _claimed;
    bool public keyClaimLive;

    function initializeV3() public reinitializer(3) {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
    }

    function isClaimed(uint256 id) virtual public view returns (bool) {
        return _claimed[id];
    }

    function toggleKeyClaim() external onlyOwner {
        keyClaimLive = !keyClaimLive;
    }
}