// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DWETH is Initializable, ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize() initializer public {
        __ERC20_init("Wrapped DeFI Ether", "DWETH");
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(MINTER_ROLE, msg.sender);
    }

    function deposit() external payable onlyRole(MINTER_ROLE) {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}