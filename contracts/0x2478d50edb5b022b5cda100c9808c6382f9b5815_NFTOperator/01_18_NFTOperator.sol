// SPDX-License-Identifier: UNLICESED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { INFTOperator } from "./interfaces/INFTOperator.sol";
import { INFT } from "./interfaces/INFT.sol";

contract NFTOperator is
    INFTOperator,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant VERSION = "1.0.0";

    event TokenTransferred(address collection, uint256 tokenId, address from, address to);
    event TokenBurnt(address collection, uint256 tokenId, address from);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    function safeTransfer(address collection, uint256 tokenId, address receiver) external nonReentrant whenNotPaused {
        INFT(collection).safeTransferFrom(msg.sender, receiver, tokenId);
        emit TokenTransferred(collection, tokenId, msg.sender, receiver);
    }

    function burn(address collection, uint256 tokenId) external nonReentrant whenNotPaused {
        INFT(collection).burn(tokenId);
        emit TokenBurnt(collection, tokenId, msg.sender);
    }
}