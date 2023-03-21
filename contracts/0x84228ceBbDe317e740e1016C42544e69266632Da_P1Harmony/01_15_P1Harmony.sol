// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Idol.sol";

contract P1Harmony is Idol, ReentrancyGuard {
    error MaxSupplyReached();
    error InvalidInput();

    constructor()
        Idol("Gemie x P1Harmony NFT Collection", "GemiexP1Harmony", 1050)
    {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function airdrop(
        address[] calldata _recipients,
        uint256[] calldata _values
    ) external nonReentrant onlyOwner {
        if (_recipients.length != _values.length) {
            revert InvalidInput();
        }

        // check supply
        uint256 total = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            total += _values[i];
        }
        if (totalSupply() + total > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // mint
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _values[i]);
        }
    }
}